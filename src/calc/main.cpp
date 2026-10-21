// Calculator: puter's calculator. Type a sum (or press the keys) and its
// result shows under it as you type; Return puts both in the history above.
// libqalculate does the arithmetic, so units, currencies, functions and
// constants work too ("5 km to miles", "sqrt(2) * pi", "20% of 85 EUR").
//
// Everything is on the 30px module: the history one row per sum, the sum
// and its result a row each, and the keypad four keys across and five down,
// each three modules wide and one tall. The keypad is drawn here; its
// colours come from the stylesheet (CalcKeypad in theme/qt/puter.qss).

#include <cmath>

#include <QAction>
#include <QApplication>
#include <QClipboard>
#include <QKeyEvent>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QMainWindow>
#include <QMenuBar>
#include <QMouseEvent>
#include <QPainter>
#include <QRegularExpression>
#include <QSettings>
#include <QStyledItemDelegate>
#include <QVBoxLayout>

#include <libqalculate/Calculator.h>

namespace {

constexpr int Module = 30;
constexpr int Inset = 8;
constexpr int Columns = 4;
constexpr int Rows = 5;
constexpr int KeyWidth = Module * 3;
constexpr int KeyHeight = Module;
constexpr int HistoryRows = 7;
constexpr int HistoryKept = 100;

// The sum's result, as Qalculate prints it (ten significant digits, in
// groups of three), or an empty string when it isn't one yet (half typed)
// or can't be worked out. Exact is the same value to 32 digits, ungrouped:
// what the next sum goes on from, so 1/3 then × 3 is 1, not 0.999 999 99.
QString evaluate(const QString &expression, int msecs, bool exact = false)
{
    if (expression.trimmed().isEmpty())
        return {};
    EvaluationOptions eo = default_user_evaluation_options;
    // Exact where it can be (1/3 × 3 is 1), printed as decimals.
    eo.approximation = APPROXIMATION_TRY_EXACT;
    // 5 km to miles is 3.106 856 mi, not 3 mi + 188 yd + 2.39 in.
    eo.mixed_units_conversion = MIXED_UNITS_CONVERSION_NONE;
    // Euros stay euros, unless the sum asks for another currency.
    eo.local_currency_conversion = false;
    eo.parse_options.unknowns_enabled = false;
    PrintOptions po = default_print_options;
    po.use_unicode_signs = true;
    po.digit_grouping = exact ? DIGIT_GROUPING_NONE : DIGIT_GROUPING_STANDARD;
    po.number_fraction_format = FRACTION_DECIMAL;
    // 1, not 1.000 000 000; 2^64 in full, and E notation only past twenty
    // digits.
    po.show_ending_zeroes = false;
    po.min_exp = 20;
    po.interval_display = INTERVAL_DISPLAY_SIGNIFICANT_DIGITS;
    po.spell_out_logical_operators = true;
    CALCULATOR->clearMessages();
    // "20% of 85" as people say it: Qalculate reads "% of" as a remainder.
    QString said = expression;
    said.replace(QRegularExpression(QStringLiteral("%\\s*of\\b")), QStringLiteral("% ×"));
    const std::string input = CALCULATOR->unlocalizeExpression(said.toStdString(), eo.parse_options);
    CALCULATOR->setPrecision(exact ? 32 : 10);
    const std::string result = CALCULATOR->calculateAndPrint(input, msecs, eo, po);
    CALCULATOR->setPrecision(10);
    // Any error (a typo, a half-finished sum) means no result.
    for (CalculatorMessage *m = CALCULATOR->message(); m; m = CALCULATOR->nextMessage())
        if (m->type() == MESSAGE_ERROR)
            return {};
    const QString text = QString::fromStdString(result);
    // A sum that is only a number gives itself back: not worth showing.
    return text == expression.trimmed() ? QString() : text;
}

// The keys, left to right and top to bottom: what each shows, what it types
// (or a command: clear, back, equals), and whether it's an operator (bone)
// rather than a digit (paper).
struct Key {
    QString label;
    QString text;
    bool operation;
};

const Key Keys[Rows][Columns] = {
    {{"C", "clear", true}, {"(", "(", true}, {")", ")", true}, {"÷", "÷", true}},
    {{"7", "7", false}, {"8", "8", false}, {"9", "9", false}, {"×", "×", true}},
    {{"4", "4", false}, {"5", "5", false}, {"6", "6", false}, {"−", "−", true}},
    {{"1", "1", false}, {"2", "2", false}, {"3", "3", false}, {"+", "+", true}},
    {{"0", "0", false}, {".", ".", false}, {"⌫", "back", true}, {"=", "equals", true}},
};

// The keypad, drawn as one grid: keys meet on 1px rules, nothing rounded,
// the one under the pointer in the hover colour, the one held down turned
// over. Colours are properties the stylesheet sets.
class CalcKeypad : public QWidget
{
    Q_OBJECT
    Q_PROPERTY(QColor digitColor MEMBER digit)
    Q_PROPERTY(QColor operatorColor MEMBER operation)
    Q_PROPERTY(QColor equalsColor MEMBER equals)
    Q_PROPERTY(QColor equalsInk MEMBER equalsInk)
    Q_PROPERTY(QColor inkColor MEMBER ink)
    Q_PROPERTY(QColor ruleColor MEMBER rule)
    Q_PROPERTY(QColor hoverColor MEMBER hover)
    Q_PROPERTY(QColor hoverInk MEMBER hoverInk)
    Q_PROPERTY(QColor pressedColor MEMBER pressed)
    Q_PROPERTY(QColor pressedInk MEMBER pressedInk)

public:
    explicit CalcKeypad(QWidget *parent = nullptr)
        : QWidget(parent)
    {
        setFixedSize(KeyWidth * Columns, KeyHeight * Rows);
        setMouseTracking(true);
        setFocusPolicy(Qt::NoFocus);
    }

signals:
    void keyPressed(const QString &text);

protected:
    void paintEvent(QPaintEvent *) override
    {
        QPainter p(this);
        for (int row = 0; row < Rows; ++row) {
            for (int column = 0; column < Columns; ++column) {
                const Key &key = Keys[row][column];
                const QRect r(column * KeyWidth, row * KeyHeight, KeyWidth, KeyHeight);
                const QPoint at(column, row);
                const bool isEquals = key.text == QLatin1String("equals");
                QColor fill = isEquals ? equals : key.operation ? operation : digit;
                QColor text = isEquals ? equalsInk : ink;
                if (at == down) {
                    fill = pressed;
                    text = pressedInk;
                } else if (at == over) {
                    fill = hover;
                    text = hoverInk;
                }
                p.fillRect(r, fill);
                p.setPen(text);
                p.drawText(r, Qt::AlignCenter, key.label);
            }
        }
        // The rules: along the top, and between keys (each on the first
        // pixel of the key to its right or below, so the keys stay whole
        // modules).
        p.setPen(Qt::NoPen);
        p.setBrush(rule);
        p.drawRect(0, 0, width(), 1);
        for (int column = 1; column < Columns; ++column)
            p.drawRect(column * KeyWidth, 0, 1, height());
        for (int row = 1; row < Rows; ++row)
            p.drawRect(0, row * KeyHeight, width(), 1);
    }

    void mouseMoveEvent(QMouseEvent *event) override { setOver(keyAt(event->position().toPoint())); }
    void leaveEvent(QEvent *) override { setOver({-1, -1}); }

    void mousePressEvent(QMouseEvent *event) override
    {
        if (event->button() != Qt::LeftButton)
            return;
        down = keyAt(event->position().toPoint());
        update();
    }

    void mouseReleaseEvent(QMouseEvent *event) override
    {
        const QPoint at = keyAt(event->position().toPoint());
        const QPoint was = down;
        down = {-1, -1};
        update();
        if (at == was && at.x() >= 0)
            emit keyPressed(Keys[at.y()][at.x()].text);
    }

private:
    QPoint keyAt(QPoint point) const
    {
        if (!rect().contains(point))
            return {-1, -1};
        return {point.x() / KeyWidth, point.y() / KeyHeight};
    }

    void setOver(QPoint at)
    {
        if (at != over) {
            over = at;
            update();
        }
    }

    QPoint over{-1, -1};
    QPoint down{-1, -1};
    QColor digit = Qt::white, operation = Qt::lightGray, equals = Qt::gray, equalsInk = Qt::black;
    QColor ink = Qt::black, rule = Qt::lightGray, hover = Qt::lightGray, hoverInk = Qt::black;
    QColor pressed = Qt::black, pressedInk = Qt::white;
};

// A history row: the sum on the left in the muted ink, its result on the
// right in ink, each elided rather than wrapped.
class HistoryDelegate : public QStyledItemDelegate
{
public:
    using QStyledItemDelegate::QStyledItemDelegate;

    QSize sizeHint(const QStyleOptionViewItem &, const QModelIndex &) const override { return {0, Module}; }

    void paint(QPainter *p, const QStyleOptionViewItem &option, const QModelIndex &index) const override
    {
        QStyleOptionViewItem plain = option;
        initStyleOption(&plain, index);
        plain.text.clear();
        option.widget->style()->drawControl(QStyle::CE_ItemViewItem, &plain, p, option.widget);

        const QString sum = index.data(Qt::DisplayRole).toString();
        const QString result = index.data(Qt::UserRole).toString();
        const QRect r = option.rect.adjusted(Inset, 0, -Inset, 0);
        p->setFont(option.font);
        // The result whole if it fits in two thirds of the row (measured in
        // fractions of a pixel: the groups are split by narrow spaces), else
        // cut from the left; the sum gets what's left.
        const QFontMetricsF fm(option.font);
        const qreal room = r.width() * 2.0 / 3.0;
        const qreal resultWidth = qMin(std::ceil(fm.horizontalAdvance(result)) + 1, room);
        const qreal sumWidth = r.width() - resultWidth - Inset;
        const QString shownResult = fm.horizontalAdvance(result) <= room ? result : fm.elidedText(result, Qt::ElideLeft, room);
        const QString shownSum = fm.horizontalAdvance(sum) <= sumWidth ? sum : fm.elidedText(sum, Qt::ElideRight, sumWidth);
        p->setPen(option.palette.color(QPalette::PlaceholderText));
        p->drawText(QRectF(r.left(), r.top(), sumWidth, r.height()), Qt::AlignLeft | Qt::AlignVCenter, shownSum);
        p->setPen(option.palette.color(QPalette::Text));
        p->drawText(QRectF(r.right() + 1 - resultWidth, r.top(), resultWidth, r.height()), Qt::AlignRight | Qt::AlignVCenter, shownResult);
    }
};

class Window : public QMainWindow
{
public:
    Window()
    {
        setWindowTitle(QStringLiteral("Calculator"));

        history.setObjectName(QStringLiteral("calcHistory"));
        history.setItemDelegate(new HistoryDelegate(&history));
        history.setSelectionMode(QAbstractItemView::NoSelection);
        history.setFocusPolicy(Qt::NoFocus);
        // No scroll bars: the wheel scrolls, and the results keep the same
        // right edge as the one under the sum.
        history.setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
        history.setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
        history.setVerticalScrollMode(QAbstractItemView::ScrollPerPixel);
        history.setUniformItemSizes(true);
        history.setMinimumHeight(Module * 2);
        // A sum from the history, clicked, comes back to be worked on.
        connect(&history, &QListWidget::itemClicked, this, [this](QListWidgetItem *item) {
            input.insert(item->data(Qt::UserRole).toString());
            input.setFocus();
        });

        input.setObjectName(QStringLiteral("calcInput"));
        input.setPlaceholderText(QStringLiteral("Type a sum"));
        input.installEventFilter(this);
        connect(&input, &QLineEdit::textChanged, this, [this] { preview(); });
        connect(&input, &QLineEdit::returnPressed, this, [this] { commit(); });

        result.setObjectName(QStringLiteral("calcResult"));
        result.setAlignment(Qt::AlignRight | Qt::AlignVCenter);
        // A styled label indents by half an x unless told not to; the
        // stylesheet's padding is the inset.
        result.setIndent(0);
        result.setTextInteractionFlags(Qt::TextSelectableByMouse);
        result.setFixedHeight(Module);
        input.setFixedHeight(Module);

        connect(&keypad, &CalcKeypad::keyPressed, this, [this](const QString &text) { press(text); });

        auto *central = new QWidget;
        auto *layout = new QVBoxLayout(central);
        layout->setContentsMargins(0, 0, 0, 0);
        layout->setSpacing(0);
        layout->addWidget(&history, 1);
        layout->addWidget(&input);
        layout->addWidget(&result);
        layout->addWidget(&keypad);
        setCentralWidget(central);

        QMenu *edit = menuBar()->addMenu(QStringLiteral("&Edit"));
        QAction *copy = edit->addAction(QStringLiteral("&Copy Result"));
        copy->setShortcut(QKeySequence(Qt::CTRL | Qt::SHIFT | Qt::Key_C));
        connect(copy, &QAction::triggered, this, [this] {
            if (!last.isEmpty())
                QApplication::clipboard()->setText(last);
        });
        QAction *clear = edit->addAction(QStringLiteral("C&lear History"));
        clear->setShortcut(QKeySequence(Qt::CTRL | Qt::Key_L));
        connect(clear, &QAction::triggered, this, [this] {
            history.clear();
            last.clear();
            lastExact.clear();
            save();
        });
        edit->addSeparator();
        QAction *rates = edit->addAction(QStringLiteral("&Update Exchange Rates"));
        connect(rates, &QAction::triggered, this, [this] {
            result.setText(QStringLiteral("Updating exchange rates…"));
            QApplication::processEvents();
            const bool ok = CALCULATOR->fetchExchangeRates(15) && CALCULATOR->loadExchangeRates();
            result.setText(ok ? QStringLiteral("Exchange rates updated") : QStringLiteral("Couldn't update exchange rates"));
        });

        QMenu *view = menuBar()->addMenu(QStringLiteral("&View"));
        QAction *keys = view->addAction(QStringLiteral("&Keypad"));
        keys->setCheckable(true);
        keys->setShortcut(QKeySequence(Qt::CTRL | Qt::Key_K));
        QSettings settings;
        keys->setChecked(settings.value(QStringLiteral("keypad"), true).toBool());
        keypad.setVisible(keys->isChecked());
        connect(keys, &QAction::toggled, this, [this](bool on) {
            // The window grows or shrinks by the keypad, the history keeping
            // its rows.
            const int change = keypad.height() * (on ? 1 : -1);
            keypad.setVisible(on);
            resize(width(), height() + change);
            QSettings().setValue(QStringLiteral("keypad"), on);
        });

        load();
        // (isVisible is false for everything until the window is shown.)
        resize(KeyWidth * Columns, Module * (1 + HistoryRows + 2) + (keys->isChecked() ? keypad.height() : 0));
        input.setFocus();
    }

protected:
    // Up and Down step through earlier sums, Escape clears the sum.
    bool eventFilter(QObject *object, QEvent *event) override
    {
        if (object == &input && event->type() == QEvent::KeyPress) {
            const int key = static_cast<QKeyEvent *>(event)->key();
            if (key == Qt::Key_Escape) {
                input.clear();
                recall = -1;
                return true;
            }
            if ((key == Qt::Key_Up || key == Qt::Key_Down) && history.count() > 0) {
                if (recall < 0)
                    recall = history.count();
                recall = qBound(0, recall + (key == Qt::Key_Up ? -1 : 1), history.count());
                input.setText(recall < history.count() ? history.item(recall)->text() : QString());
                return true;
            }
        }
        return QMainWindow::eventFilter(object, event);
    }

private:
    void press(const QString &text)
    {
        if (text == QLatin1String("clear")) {
            input.clear();
        } else if (text == QLatin1String("back")) {
            input.backspace();
        } else if (text == QLatin1String("equals")) {
            commit();
        } else {
            input.insert(text);
        }
        input.setFocus();
    }

    // A sum starting with an operator goes on from the last result, as on a
    // pocket calculator: worked out from its exact value, shown (in the
    // history) with the value as printed.
    bool continues() const
    {
        const QString text = input.text().trimmed();
        static const QString operators = QStringLiteral("+−-×*÷/^");
        return !lastExact.isEmpty() && !text.isEmpty() && operators.contains(text.front());
    }

    QString sum() const
    {
        const QString text = input.text().trimmed();
        return continues() ? QStringLiteral("(") + lastExact + QStringLiteral(") ") + text : text;
    }

    QString shownSum() const
    {
        const QString text = input.text().trimmed();
        return continues() ? last + QLatin1Char(' ') + text : text;
    }

    void preview()
    {
        recall = -1;
        const QString value = evaluate(sum(), 250);
        result.setProperty("final", false);
        result.setText(value.isEmpty() ? QString() : QStringLiteral("= ") + value);
        result.style()->unpolish(&result);
        result.style()->polish(&result);
    }

    void commit()
    {
        const QString text = sum();
        const QString value = evaluate(text, 5000);
        if (value.isEmpty())
            return;
        add(shownSum(), value, evaluate(text, 5000, true));
        last = value;
        lastExact = history.item(history.count() - 1)->data(Qt::UserRole + 1).toString();
        input.clear();
        result.setText(QStringLiteral("= ") + value);
        result.setProperty("final", true);
        result.style()->unpolish(&result);
        result.style()->polish(&result);
        save();
    }

    void add(const QString &text, const QString &value, const QString &exact)
    {
        auto *item = new QListWidgetItem(text);
        item->setData(Qt::UserRole, value);
        item->setData(Qt::UserRole + 1, exact);
        item->setToolTip(text + QStringLiteral(" = ") + value);
        history.addItem(item);
        while (history.count() > HistoryKept)
            delete history.takeItem(0);
        history.scrollToBottom();
    }

    // The history is kept between runs.
    void load()
    {
        QSettings settings;
        const QStringList sums = settings.value(QStringLiteral("history/sums")).toStringList();
        const QStringList results = settings.value(QStringLiteral("history/results")).toStringList();
        const QStringList exacts = settings.value(QStringLiteral("history/exact")).toStringList();
        for (qsizetype i = 0; i < qMin(sums.size(), results.size()); ++i)
            add(sums[i], results[i], i < exacts.size() ? exacts[i] : results[i]);
        if (history.count() > 0) {
            last = history.item(history.count() - 1)->data(Qt::UserRole).toString();
            lastExact = history.item(history.count() - 1)->data(Qt::UserRole + 1).toString();
        }
    }

    void save()
    {
        QStringList sums, results, exacts;
        for (int i = 0; i < history.count(); ++i) {
            sums << history.item(i)->text();
            results << history.item(i)->data(Qt::UserRole).toString();
            exacts << history.item(i)->data(Qt::UserRole + 1).toString();
        }
        QSettings settings;
        settings.setValue(QStringLiteral("history/sums"), sums);
        settings.setValue(QStringLiteral("history/results"), results);
        settings.setValue(QStringLiteral("history/exact"), exacts);
    }

    QListWidget history;
    QLineEdit input;
    QLabel result;
    CalcKeypad keypad;
    QString last;
    QString lastExact;
    int recall = -1;
};

} // namespace

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QApplication::setOrganizationName(QStringLiteral("puter"));
    QApplication::setApplicationName(QStringLiteral("calc"));
    QApplication::setDesktopFileName(QStringLiteral("puter-calc"));

    new Calculator();
    CALCULATOR->setPrecision(10);
    CALCULATOR->loadExchangeRates();
    CALCULATOR->loadGlobalDefinitions();
    CALCULATOR->loadLocalDefinitions();

    Window window;
    window.show();
    const int status = app.exec();
    CALCULATOR->terminateThreads();
    return status;
}

#include "main.moc"
