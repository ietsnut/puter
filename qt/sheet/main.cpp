// Sheet: puter's table editor. Opens a CSV or TSV file into a grid, edits it
// cell by cell, adds and removes rows and columns, undoes all of it, and saves
// it back with the delimiter it came with. Rows are one 30px module and
// columns five; a column dragged wider or narrower keeps to whole modules.

#include <QAction>
#include <QApplication>
#include <QCloseEvent>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QHeaderView>
#include <QInputDialog>
#include <QKeySequence>
#include <QMainWindow>
#include <QMenuBar>
#include <QMessageBox>
#include <QStringDecoder>
#include <QTableView>
#include <QUndoStack>
#include <QAbstractTableModel>
#include <QShowEvent>

namespace {

constexpr int Module = 30;
constexpr int ColumnModules = 5;

// CSV as RFC 4180 has it: fields split by the delimiter, quoted when they
// hold the delimiter, a quote or a line break, quotes inside doubled.
QList<QStringList> parse(const QString &text, QChar delimiter)
{
    QList<QStringList> rows;
    QStringList row;
    QString field;
    bool quoted = false;
    for (qsizetype i = 0; i < text.size(); ++i) {
        const QChar c = text[i];
        if (quoted) {
            if (c == '"' && i + 1 < text.size() && text[i + 1] == '"') {
                field += '"';
                ++i;
            } else if (c == '"') {
                quoted = false;
            } else {
                field += c;
            }
        } else if (c == '"') {
            quoted = true;
        } else if (c == delimiter) {
            row << field;
            field.clear();
        } else if (c == '\n' || c == '\r') {
            if (c == '\r' && i + 1 < text.size() && text[i + 1] == '\n')
                ++i;
            row << field;
            field.clear();
            rows << row;
            row.clear();
        } else {
            field += c;
        }
    }
    if (!field.isEmpty() || !row.isEmpty()) {
        row << field;
        rows << row;
    }
    return rows;
}

QString write(const QList<QStringList> &rows, QChar delimiter)
{
    QString out;
    for (const QStringList &row : rows) {
        QStringList fields;
        for (QString field : row) {
            if (field.contains(delimiter) || field.contains('"') || field.contains('\n') || field.contains('\r')) {
                field.replace('"', QStringLiteral("\"\""));
                field = '"' + field + '"';
            }
            fields << field;
        }
        out += fields.join(delimiter) + '\n';
    }
    return out;
}

// The delimiter the first lines agree on: tab, semicolon, pipe or comma.
QChar sniff(const QString &text, const QString &path)
{
    if (path.endsWith(QLatin1String(".tsv"), Qt::CaseInsensitive))
        return '\t';
    const QString head = text.left(4096);
    QChar best = ',';
    qsizetype most = head.count(',');
    for (QChar c : {QChar('\t'), QChar(';'), QChar('|')}) {
        if (head.count(c) > most) {
            most = head.count(c);
            best = c;
        }
    }
    return best;
}

class Table : public QAbstractTableModel {
public:
    QList<QStringList> rows;
    bool header = false;

    int columns() const
    {
        int n = 0;
        for (const QStringList &row : rows)
            n = std::max(n, int(row.size()));
        return n;
    }
    int rowCount(const QModelIndex &parent = {}) const override
    {
        return parent.isValid() ? 0 : std::max(0, int(rows.size()) - (header ? 1 : 0));
    }
    int columnCount(const QModelIndex &parent = {}) const override { return parent.isValid() ? 0 : columns(); }
    int fileRow(int row) const { return row + (header ? 1 : 0); }

    QString cell(int fileRowIndex, int column) const
    {
        const QStringList &row = rows.at(fileRowIndex);
        return column < row.size() ? row.at(column) : QString();
    }
    void setCell(int fileRowIndex, int column, const QString &value)
    {
        QStringList &row = rows[fileRowIndex];
        while (row.size() <= column)
            row << QString();
        row[column] = value;
        const int shown = fileRowIndex - (header ? 1 : 0);
        if (shown >= 0)
            emit dataChanged(index(shown, column), index(shown, column));
        else
            emit headerDataChanged(Qt::Horizontal, column, column);
    }

    QVariant data(const QModelIndex &index, int role) const override
    {
        if (role == Qt::DisplayRole || role == Qt::EditRole)
            return cell(fileRow(index.row()), index.column());
        return {};
    }
    QVariant headerData(int section, Qt::Orientation orientation, int role) const override
    {
        if (role != Qt::DisplayRole)
            return {};
        if (orientation == Qt::Vertical)
            return section + 1 + (header ? 1 : 0);
        if (header && !rows.isEmpty())
            return cell(0, section);
        // Spreadsheet letters: A..Z, AA..
        QString name;
        for (int n = section + 1; n > 0; n = (n - 1) / 26)
            name.prepend(QChar('A' + (n - 1) % 26));
        return name;
    }
    Qt::ItemFlags flags(const QModelIndex &index) const override
    {
        return QAbstractTableModel::flags(index) | Qt::ItemIsEditable;
    }
    bool setData(const QModelIndex &index, const QVariant &value, int role) override;

    QUndoStack *undo = nullptr;

    void setHeader(bool on)
    {
        beginResetModel();
        header = on;
        endResetModel();
    }
    void reset(QList<QStringList> newRows)
    {
        beginResetModel();
        rows = std::move(newRows);
        endResetModel();
    }
};

// Undo works on snapshots of the whole table: a file small enough to edit by
// hand is small enough to copy, and one kind of command covers every edit.
class Change : public QUndoCommand {
public:
    Change(Table *table, QList<QStringList> after, const QString &text)
        : QUndoCommand(text), table(table), before(table->rows), after(std::move(after)) {}
    void undo() override { table->reset(before); }
    void redo() override { table->reset(after); }
private:
    Table *table;
    QList<QStringList> before, after;
};

bool Table::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (role != Qt::EditRole || value.toString() == data(index, Qt::EditRole).toString())
        return false;
    QList<QStringList> after = rows;
    QStringList &row = after[fileRow(index.row())];
    while (row.size() <= index.column())
        row << QString();
    row[index.column()] = value.toString();
    undo->push(new Change(this, after, QStringLiteral("Edit Cell")));
    return true;
}

class Window : public QMainWindow {
public:
    explicit Window(const QString &path)
    {
        table.undo = &undo;
        view.setModel(&table);
        view.setShowGrid(true);
        view.setCornerButtonEnabled(false);
        view.verticalHeader()->setDefaultSectionSize(Module);
        view.verticalHeader()->setMinimumSectionSize(Module);
        view.verticalHeader()->setSectionResizeMode(QHeaderView::Fixed);
        view.verticalHeader()->setDefaultAlignment(Qt::AlignRight | Qt::AlignVCenter);
        view.horizontalHeader()->setDefaultSectionSize(ColumnModules * Module);
        view.horizontalHeader()->setMinimumSectionSize(Module);
        view.horizontalHeader()->setDefaultAlignment(Qt::AlignLeft | Qt::AlignVCenter);
        view.horizontalHeader()->setHighlightSections(false);
        view.verticalHeader()->setHighlightSections(false);
        // A dragged column ends on the grid.
        connect(view.horizontalHeader(), &QHeaderView::sectionResized, this, [this](int section, int, int size) {
            const int snapped = std::max(1, (size + Module / 2) / Module) * Module;
            if (snapped != size)
                view.horizontalHeader()->resizeSection(section, snapped);
        });
        // The row numbers are a whole number of modules wide.
        connect(&table, &QAbstractItemModel::modelReset, this, [this] { fitRowNumbers(); });
        setCentralWidget(&view);
        buildMenus();
        connect(&undo, &QUndoStack::cleanChanged, this, [this] { showTitle(); });
        if (path.isEmpty())
            table.reset({QStringList(5), QStringList(5), QStringList(5)});
        else
            open(path);
        undo.setClean();
        showTitle();
        resize(30 * Module, 20 * Module);
    }

protected:
    // Once shown, the stylesheet has had its say about the headers' sizes;
    // the grid's are set again over it.
    void showEvent(QShowEvent *event) override
    {
        QMainWindow::showEvent(event);
        view.verticalHeader()->setMinimumSectionSize(Module);
        view.verticalHeader()->setDefaultSectionSize(Module);
        view.horizontalHeader()->setDefaultSectionSize(ColumnModules * Module);
        fitRowNumbers();
    }

    void closeEvent(QCloseEvent *event) override
    {
        if (keepChanges())
            event->accept();
        else
            event->ignore();
    }

private:
    Table table;
    QTableView view;
    QUndoStack undo;
    QString path;
    QChar delimiter = ',';
    QAction *headerAction = nullptr;

    void fitRowNumbers()
    {
        const int digits = QString::number(table.rows.size() + 1).size();
        const int width = view.fontMetrics().horizontalAdvance(QString(digits, '0')) + 16;
        view.verticalHeader()->setFixedWidth((width + Module - 1) / Module * Module);
    }

    void showTitle()
    {
        const QString name = path.isEmpty() ? QStringLiteral("Untitled") : QFileInfo(path).fileName();
        setWindowTitle((undo.isClean() ? QString() : QStringLiteral("* ")) + name + QStringLiteral(" - Sheet"));
    }

    // Asks before throwing away unsaved changes; true when it's fine to go on.
    bool keepChanges()
    {
        if (undo.isClean())
            return true;
        const auto answer = QMessageBox::question(this, QStringLiteral("Save Changes?"),
            QStringLiteral("Save the changes to %1?").arg(path.isEmpty() ? QStringLiteral("this table") : QFileInfo(path).fileName()),
            QMessageBox::Save | QMessageBox::Discard | QMessageBox::Cancel, QMessageBox::Save);
        if (answer == QMessageBox::Save)
            return save();
        return answer == QMessageBox::Discard;
    }

    void open(const QString &file)
    {
        QFile in(file);
        if (!in.open(QIODevice::ReadOnly)) {
            QMessageBox::warning(this, QStringLiteral("Could Not Open"), in.errorString());
            return;
        }
        const QString text = QString::fromUtf8(in.readAll());
        delimiter = sniff(text, file);
        path = file;
        // Most tables start with their column names; the first row is taken
        // as a header (View > First Row Is a Header turns it off).
        table.header = true;
        if (headerAction)
            headerAction->setChecked(true);
        table.reset(parse(text, delimiter));
        undo.clear();
        showTitle();
    }

    bool saveTo(const QString &file)
    {
        QFile out(file);
        if (!out.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            QMessageBox::warning(this, QStringLiteral("Could Not Save"), out.errorString());
            return false;
        }
        out.write(write(table.rows, delimiter).toUtf8());
        path = file;
        undo.setClean();
        showTitle();
        return true;
    }
    bool save() { return path.isEmpty() ? saveAs() : saveTo(path); }
    bool saveAs()
    {
        const QString file = QFileDialog::getSaveFileName(this, QStringLiteral("Save As"), path,
            QStringLiteral("Tables (*.csv *.tsv);;All Files (*)"));
        if (file.isEmpty())
            return false;
        if (file.endsWith(QLatin1String(".tsv"), Qt::CaseInsensitive))
            delimiter = '\t';
        return saveTo(file);
    }

    // The row or column the cursor is in, in the file's own numbering.
    int currentFileRow() const
    {
        const QModelIndex at = view.currentIndex();
        return at.isValid() ? table.fileRow(at.row()) : int(table.rows.size()) - 1;
    }
    int currentColumn() const
    {
        const QModelIndex at = view.currentIndex();
        return at.isValid() ? at.column() : table.columns() - 1;
    }

    void change(QList<QStringList> after, const QString &text) { undo.push(new Change(&table, std::move(after), text)); }

    void insertRow(int offset)
    {
        QList<QStringList> after = table.rows;
        const int at = std::clamp(currentFileRow() + offset, table.header ? 1 : 0, int(after.size()));
        after.insert(at, QStringList(table.columns()));
        change(after, QStringLiteral("Insert Row"));
    }
    void removeRow()
    {
        if (table.rowCount() == 0)
            return;
        QList<QStringList> after = table.rows;
        after.removeAt(currentFileRow());
        change(after, QStringLiteral("Delete Row"));
    }
    void insertColumn(int offset)
    {
        QList<QStringList> after = table.rows;
        const int at = std::clamp(currentColumn() + offset, 0, table.columns());
        for (QStringList &row : after) {
            while (row.size() < at)
                row << QString();
            row.insert(at, QString());
        }
        change(after, QStringLiteral("Insert Column"));
    }
    void removeColumn()
    {
        if (table.columns() == 0)
            return;
        const int at = currentColumn();
        QList<QStringList> after = table.rows;
        for (QStringList &row : after)
            if (at < row.size())
                row.removeAt(at);
        change(after, QStringLiteral("Delete Column"));
    }
    void renameColumn(int column)
    {
        if (!table.header || table.rows.isEmpty())
            return;
        bool ok = false;
        const QString name = QInputDialog::getText(this, QStringLiteral("Rename Column"), QStringLiteral("Name"),
            QLineEdit::Normal, table.cell(0, column), &ok);
        if (!ok)
            return;
        QList<QStringList> after = table.rows;
        while (after[0].size() <= column)
            after[0] << QString();
        after[0][column] = name;
        change(after, QStringLiteral("Rename Column"));
    }
    void clearCells()
    {
        const QModelIndexList cells = view.selectionModel()->selectedIndexes();
        if (cells.isEmpty())
            return;
        QList<QStringList> after = table.rows;
        for (const QModelIndex &cell : cells) {
            QStringList &row = after[table.fileRow(cell.row())];
            if (cell.column() < row.size())
                row[cell.column()].clear();
        }
        change(after, QStringLiteral("Clear"));
    }

    QAction *add(QMenu *menu, const QString &text, QKeySequence keys, std::function<void()> act)
    {
        QAction *action = menu->addAction(text);
        if (!keys.isEmpty())
            action->setShortcut(keys);
        connect(action, &QAction::triggered, this, act);
        return action;
    }

    void buildMenus()
    {
        QMenu *file = menuBar()->addMenu(QStringLiteral("&File"));
        add(file, QStringLiteral("&New Window"), QKeySequence::New, [] { (new Window(QString()))->show(); });
        add(file, QStringLiteral("&Open…"), QKeySequence::Open, [this] {
            if (!keepChanges())
                return;
            const QString file = QFileDialog::getOpenFileName(this, QStringLiteral("Open"), path,
                QStringLiteral("Tables (*.csv *.tsv *.txt);;All Files (*)"));
            if (!file.isEmpty())
                open(file);
        });
        file->addSeparator();
        add(file, QStringLiteral("&Save"), QKeySequence::Save, [this] { save(); });
        add(file, QStringLiteral("Save &As…"), QKeySequence::SaveAs, [this] { saveAs(); });
        file->addSeparator();
        add(file, QStringLiteral("&Close"), QKeySequence::Close, [this] { close(); });

        QMenu *edit = menuBar()->addMenu(QStringLiteral("&Edit"));
        QAction *undoAction = undo.createUndoAction(this, QStringLiteral("&Undo"));
        undoAction->setShortcut(QKeySequence::Undo);
        QAction *redoAction = undo.createRedoAction(this, QStringLiteral("&Redo"));
        redoAction->setShortcut(QKeySequence::Redo);
        edit->addAction(undoAction);
        edit->addAction(redoAction);
        edit->addSeparator();
        add(edit, QStringLiteral("C&lear"), QKeySequence::Delete, [this] { clearCells(); });

        QMenu *row = menuBar()->addMenu(QStringLiteral("&Row"));
        add(row, QStringLiteral("Insert &Above"), {}, [this] { insertRow(0); });
        add(row, QStringLiteral("Insert &Below"), QKeySequence(Qt::CTRL | Qt::Key_Return), [this] { insertRow(1); });
        row->addSeparator();
        add(row, QStringLiteral("&Delete Row"), QKeySequence(Qt::CTRL | Qt::Key_Minus), [this] { removeRow(); });

        QMenu *column = menuBar()->addMenu(QStringLiteral("&Column"));
        add(column, QStringLiteral("Insert &Left"), {}, [this] { insertColumn(0); });
        add(column, QStringLiteral("Insert &Right"), QKeySequence(Qt::CTRL | Qt::SHIFT | Qt::Key_Return), [this] { insertColumn(1); });
        column->addSeparator();
        add(column, QStringLiteral("Re&name…"), {}, [this] { renameColumn(currentColumn()); });
        add(column, QStringLiteral("&Delete Column"), QKeySequence(Qt::CTRL | Qt::SHIFT | Qt::Key_Minus), [this] { removeColumn(); });

        QMenu *viewMenu = menuBar()->addMenu(QStringLiteral("&View"));
        headerAction = viewMenu->addAction(QStringLiteral("First Row Is a &Header"));
        headerAction->setCheckable(true);
        connect(headerAction, &QAction::toggled, this, [this](bool on) { table.setHeader(on); });
        connect(view.horizontalHeader(), &QHeaderView::sectionDoubleClicked, this, [this](int section) { renameColumn(section); });
    }
};

} // namespace

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QApplication::setApplicationName(QStringLiteral("Sheet"));
    QApplication::setDesktopFileName(QStringLiteral("puter-sheet"));
    const QStringList args = QApplication::arguments();
    auto *window = new Window(args.size() > 1 ? args.at(1) : QString());
    window->setAttribute(Qt::WA_DeleteOnClose);
    window->show();
    return app.exec();
}
