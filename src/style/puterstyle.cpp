// puter's Qt widget style: Fusion's drawing, with puter's grid. Every menu
// bar, menu item, toolbar button, push button, field, list row, header and
// tab is one 30px module tall; toolbars and menu bars add no frame or margin
// of their own; icons in bars and lists are 16px. Colours, outlines and rules
// are the stylesheet's (theme/qt/puter.qss), not this. Every dialog is laid
// on the grid when it's shown, and libfm-qt's file dialog, every app's through
// the portal, is pared down too.

#include <QProxyStyle>
#include <QStyleFactory>
#include <QStylePlugin>
#include <QStyleOption>
#include <QAbstractItemView>
#include <QAbstractSpinBox>
#include <QCheckBox>
#include <QComboBox>
#include <QDialog>
#include <QDialogButtonBox>
#include <QBoxLayout>
#include <QEvent>
#include <QFrame>
#include <QHeaderView>
#include <QLabel>
#include <QLayout>
#include <QLineEdit>
#include <QListWidget>
#include <QMainWindow>
#include <QPushButton>
#include <QRadioButton>
#include <QScrollArea>
#include <QScrollBar>
#include <QTimer>
#include <QToolBar>
#include <QToolButton>
#include <QWidget>

namespace {

constexpr int Module = 30;
constexpr int Inset = 8;
constexpr int Icon = 16;

// A length rounded up to whole modules.
int modules(int length)
{
    return (length + Module - 1) / Module * Module;
}

// A window whole modules wide and tall, rounding up whatever it would be (an
// app's saved size, its layout's).
void roundSize(QWidget *window)
{
    const QSize size = window->size().expandedTo(window->minimumSizeHint());
    window->resize(modules(size.width()), modules(size.height()));
}

// Any dialog on the grid: its labels, buttons, fields and boxes at least
// whole modules wide and tall (the stylesheet sizes most of them, from their
// text, so this rounds what it gives up), buttons in a row a module apart,
// and the dialog itself whole modules: a module around what's in it and
// nothing between its parts. Apps often set their own margins and spacing
// (Designer files do), so the layouts are set here, not only through the
// layout metrics below; fixed spacers round up to whole modules.
void gridDialog(QDialog *dialog)
{
    for (auto *layout : dialog->findChildren<QLayout *>()) {
        const int margin = layout == dialog->layout() ? Module : 0;
        layout->setContentsMargins(margin, margin, margin, margin);
        layout->setSpacing(0);
        for (int i = 0; i < layout->count(); ++i)
            if (auto *spacer = layout->itemAt(i)->spacerItem()) {
                const QSizePolicy policy = spacer->sizePolicy();
                const QSize hint = spacer->sizeHint();
                spacer->changeSize(modules(hint.width()), modules(hint.height()),
                                   policy.horizontalPolicy(), policy.verticalPolicy());
            }
        layout->invalidate();
    }
    for (auto *widget : dialog->findChildren<QWidget *>()) {
        // Lists beside a dialog's pages (its sections): whole modules wide,
        // their icons 16px as in every list.
        if (auto *list = qobject_cast<QAbstractItemView *>(widget);
            list && list->maximumWidth() < QWIDGETSIZE_MAX) {
            list->setFixedWidth(modules(list->maximumWidth()));
            list->setIconSize(QSize(Icon, Icon));
            // A module a row, whatever size the app gave its items.
            if (auto *items = qobject_cast<QListWidget *>(list))
                for (int i = 0; i < items->count(); ++i)
                    items->item(i)->setSizeHint(QSize(items->item(i)->sizeHint().width(), Module));
            continue;
        }
        // Separator lines between sections: left out, as the headings part
        // them (a line's few pixels would set all below it off the grid).
        if (auto *frame = qobject_cast<QFrame *>(widget);
            frame && (frame->frameShape() == QFrame::HLine || frame->frameShape() == QFrame::VLine)) {
            frame->hide();
            continue;
        }
        if (!(qobject_cast<QLabel *>(widget) || qobject_cast<QPushButton *>(widget)
              || qobject_cast<QCheckBox *>(widget) || qobject_cast<QRadioButton *>(widget)
              || qobject_cast<QComboBox *>(widget) || qobject_cast<QLineEdit *>(widget)
              || qobject_cast<QAbstractSpinBox *>(widget)))
            continue;
        // A line edit inside a combo or spin box is sized by its box.
        if (qobject_cast<QLineEdit *>(widget) && widget->parentWidget()
            && (qobject_cast<QComboBox *>(widget->parentWidget()) || qobject_cast<QAbstractSpinBox *>(widget->parentWidget())))
            continue;
        const QSize hint = widget->sizeHint();
        if (!hint.isValid())
            continue;
        widget->setMinimumWidth(modules(hint.width()));
        // A label may wrap onto more lines, so it rounds up; every other
        // one is a single line, one module tall exactly (its hint may be a
        // pixel or two over).
        if (qobject_cast<QLabel *>(widget))
            widget->setMinimumHeight(modules(hint.height()));
        else
            widget->setFixedHeight(Module);
    }
    // A scroll area as wide as what it holds and its scroll bar, so nothing
    // scrolls sideways (the rounding above widens what it holds).
    for (auto *area : dialog->findChildren<QScrollArea *>())
        if (area->widget() && area->widgetResizable()) {
            area->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
            area->setMinimumWidth(modules(area->widget()->minimumSizeHint().width()
                                          + area->verticalScrollBar()->sizeHint().width()
                                          + 2 * area->frameWidth()));
        }
    // Buttons side by side outside a button box, a module apart too.
    for (auto *row : dialog->findChildren<QBoxLayout *>()) {
        int buttons = 0;
        for (int i = 0; i < row->count(); ++i)
            if (qobject_cast<QPushButton *>(row->itemAt(i)->widget()))
                ++buttons;
        if (buttons > 1)
            row->setSpacing(Module);
    }
    // The dialog's buttons a module apart, and a module below what's above.
    for (auto *buttons : dialog->findChildren<QDialogButtonBox *>()) {
        if (buttons->layout())
            buttons->layout()->setSpacing(Module);
        buttons->setContentsMargins(0, Module, 0, 0);
    }
    if (dialog->layout())
        dialog->layout()->activate();
    roundSize(dialog);
}

// libfm-qt's file dialog as the path bar, the list, and under it one row of
// the file name and its buttons (two, with the file type, when there's a
// choice of types), all flush: no side pane (the path bar reaches every
// folder), toolbar (its shortcuts stay: Alt+Left, Alt+Right, F5) or labels.
// Its widgets are found by the names in libfm-qt's filedialog.ui.
void pareFileDialog(QDialog *dialog)
{
    for (const char *name : {"lookInLabel", "sidePane", "fileNameLabel", "fileTypeLabel"})
        if (auto *widget = dialog->findChild<QWidget *>(QLatin1String(name)))
            widget->hide();
    for (auto *toolbar : dialog->findChildren<QToolBar *>(Qt::FindDirectChildrenOnly)) {
        dialog->addActions(toolbar->actions());
        toolbar->hide();
    }

    auto *types = dialog->findChild<QComboBox *>(QStringLiteral("fileTypeCombo"));
    const bool oneType = !types || types->count() <= 1;
    if (types)
        types->setVisible(!oneType);
    if (auto *buttons = dialog->findChild<QDialogButtonBox *>(QStringLiteral("buttonBox"))) {
        buttons->setOrientation(oneType ? Qt::Horizontal : Qt::Vertical);
        // Only as wide as its buttons, so the file name takes the rest.
        buttons->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
        buttons->setContentsMargins(0, 0, 0, 0);
        buttons->layout()->setContentsMargins(0, 0, 0, 0);
        buttons->layout()->setSpacing(0);
        for (auto *button : buttons->buttons())
            button->setFixedWidth(4 * Module);
    }

    for (const char *name : {"verticalLayout", "toolbarLayout", "gridLayout"})
        if (auto *layout = dialog->findChild<QLayout *>(QLatin1String(name))) {
            layout->setContentsMargins(0, 0, 0, 0);
            layout->setSpacing(0);
        }
}

class PuterStyle : public QProxyStyle {
public:
    PuterStyle() : QProxyStyle(QStyleFactory::create(QStringLiteral("Fusion"))) {}

    void polish(QWidget *widget) override
    {
        QProxyStyle::polish(widget);
        // Columns whole modules wide, whatever width an app or a drag gives
        // them (the last one, stretched to the view's edge, takes the rest).
        if (auto *header = qobject_cast<QHeaderView *>(widget)) {
            // Only sections the app sizes: not hidden ones, nor those Qt sizes
            // itself (stretched, fitted to their contents, the last one
            // stretched to the edge), and never from inside its own resize.
            auto snap = [header](int section) {
                int last = header->count() - 1;  // the last visible one
                while (last > 0 && header->isSectionHidden(header->logicalIndex(last)))
                    --last;
                if (header->property("puterSnapping").toBool() || header->isSectionHidden(section)
                    || header->sectionResizeMode(section) == QHeaderView::Stretch
                    || header->sectionResizeMode(section) == QHeaderView::ResizeToContents
                    || (header->stretchLastSection() && header->visualIndex(section) == last))
                    return;
                const int width = header->sectionSize(section);
                if (width % Module == 0)
                    return;
                // Up, unless the columns would then overrun the view: down.
                int snapped = modules(width);
                if (header->length() - width + snapped > header->viewport()->width() && width >= Module)
                    snapped = width - width % Module;
                header->setProperty("puterSnapping", true);
                header->resizeSection(section, snapped);
                header->setProperty("puterSnapping", false);
            };
            // Once per header (a lambda can't be a unique connection).
            if (!header->property("puterSnap").toBool()) {
                header->setProperty("puterSnap", true);
                connect(header, &QHeaderView::sectionResized, header, [snap](int section, int, int) { snap(section); });
            }
            for (int section = 0; section < header->count(); ++section)
                snap(section);
        }
        if (qobject_cast<QDialog *>(widget) || qobject_cast<QMainWindow *>(widget)
            || qobject_cast<QToolButton *>(widget) || widget->windowType() == Qt::Window)
            widget->installEventFilter(this);
    }

    void unpolish(QWidget *widget) override
    {
        if (qobject_cast<QDialog *>(widget) || qobject_cast<QMainWindow *>(widget)
            || qobject_cast<QToolButton *>(widget) || widget->windowType() == Qt::Window)
            widget->removeEventFilter(this);
        QProxyStyle::unpolish(widget);
    }

    // Dialogs are laid on the grid each time they're shown: what's in them
    // (the file dialog's file types, a message's text) is only known by then.
    // Main windows open whole modules wide and tall.
    bool eventFilter(QObject *object, QEvent *event) override
    {
        if (event->type() == QEvent::Show) {
            if (auto *dialog = qobject_cast<QDialog *>(object)) {
                gridDialog(dialog);
                if (dialog->inherits("Fm::FileDialog"))
                    pareFileDialog(dialog);
                // And again once it's up: some apps size their dialogs after
                // showing them (LXImage-Qt's preferences).
                QTimer::singleShot(0, dialog, [dialog] { roundSize(dialog); });
            } else if (auto *window = qobject_cast<QMainWindow *>(object); window && window->isWindow()) {
                // Flush, part on part, whatever margins and spacing the app
                // gave its bars (Falkon's navigation bar keeps 3px round it).
                for (auto *layout : window->findChildren<QLayout *>()) {
                    layout->setContentsMargins(0, 0, 0, 0);
                    layout->setSpacing(0);
                }
                roundSize(window);
            } else if (auto *window = qobject_cast<QWidget *>(object);
                       window && window->windowType() == Qt::Window && !qobject_cast<QToolButton *>(object)) {
                // Any other window of its own (some apps' main window is a plain
                // widget): whole modules too.
                roundSize(window);
            } else if (auto *button = qobject_cast<QToolButton *>(object);
                       button && button->toolButtonStyle() != Qt::ToolButtonIconOnly) {
                // A button with words (a path bar's folders): whole modules
                // wide, as the stylesheet sizes it from its text.
                button->setMinimumWidth(modules(button->sizeHint().width()));
            }
        }
        return QProxyStyle::eventFilter(object, event);
    }

    int pixelMetric(PixelMetric metric, const QStyleOption *option, const QWidget *widget) const override
    {
        switch (metric) {
        // Bars hold their items flush: no frame, margin or spacing.
        case PM_ToolBarFrameWidth:
        case PM_ToolBarItemMargin:
        case PM_ToolBarItemSpacing:
        case PM_ToolBarHandleExtent:
        case PM_MenuBarPanelWidth:
        case PM_MenuBarItemSpacing:
        case PM_MenuBarVMargin:
        case PM_MenuBarHMargin:
        case PM_MenuHMargin:
        case PM_MenuVMargin:
        case PM_MenuTearoffHeight:
            return 0;
        // Everything is laid out flush, part on part, so each stays on the
        // grid; only a dialog keeps a module between its outline and what's
        // in it (a main window's bars meet its outline).
        case PM_LayoutHorizontalSpacing:
        case PM_LayoutVerticalSpacing:
            return 0;
        case PM_LayoutLeftMargin:
        case PM_LayoutTopMargin:
        case PM_LayoutRightMargin:
        case PM_LayoutBottomMargin:
            return widget && widget->isWindow() && qobject_cast<const QDialog *>(widget) ? Module : 0;
        case PM_ToolBarSeparatorExtent:
        case PM_MenuPanelWidth:
        case PM_DefaultFrameWidth:
            return 1;
        case PM_ToolBarIconSize:
        case PM_SmallIconSize:
        case PM_ButtonIconSize:
        case PM_ListViewIconSize:
        case PM_TabBarIconSize:
            return Icon;
        // Table rows are a module, table columns five.
        case PM_HeaderDefaultSectionSizeVertical:
            return Module;
        case PM_HeaderDefaultSectionSizeHorizontal:
            return 5 * Module;
        case PM_ScrollBarExtent:
            return Module;
        // A tab's close button is a module square (the stylesheet centres
        // its 16px glyph in it).
        case PM_TabCloseIndicatorWidth:
        case PM_TabCloseIndicatorHeight:
            return Module;
        case PM_TabBarTabHSpace:
            return 2 * Inset;
        case PM_TabBarTabVSpace:
        // The chosen tab's label stays where the others' are.
        case PM_TabBarTabShiftVertical:
        case PM_TabBarTabShiftHorizontal:
            return 0;
        case PM_HeaderMargin:
            return Inset;
        default:
            return QProxyStyle::pixelMetric(metric, option, widget);
        }
    }

    // A tab's close button fills the tab's last module, flush with its right
    // edge (the base style keeps half the tab's padding beside it, which
    // left it off the grid).
    QRect subElementRect(SubElement element, const QStyleOption *option, const QWidget *widget) const override
    {
        if (element == SE_TabBarTabRightButton && option)
            return QRect(option->rect.right() + 1 - Module, option->rect.top(), Module, Module);
        return QProxyStyle::subElementRect(element, option, widget);
    }

    QSize sizeFromContents(ContentsType type, const QStyleOption *option, const QSize &contents,
                           const QWidget *widget) const override
    {
        QSize size = QProxyStyle::sizeFromContents(type, option, contents, widget);
        switch (type) {
        case CT_MenuBarItem:
            return {contents.width() + 2 * Inset, Module};
        case CT_MenuItem:
            if (const auto *item = qstyleoption_cast<const QStyleOptionMenuItem *>(option);
                item && item->menuItemType == QStyleOptionMenuItem::Separator)
                return {size.width(), 1};
            return {size.width(), Module};
        case CT_ToolButton:
            if (const auto *button = qstyleoption_cast<const QStyleOptionToolButton *>(option);
                button && button->toolButtonStyle == Qt::ToolButtonIconOnly)
                return {Module, Module};
            return {contents.width() + 2 * Inset, Module};
        case CT_PushButton:
        case CT_LineEdit:
        case CT_ComboBox:
        case CT_SpinBox:
        case CT_ItemViewItem:
            return {size.width(), Module};
        case CT_HeaderSection:
            return {modules(size.width()), Module};
        case CT_TabBarTab:
            return {modules(size.width()), Module};
        default:
            return size;
        }
    }
};

class PuterStylePlugin : public QStylePlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QStyleFactoryInterface_iid FILE "puterstyle.json")
public:
    QStyle *create(const QString &key) override
    {
        return key.compare(QLatin1String("puter"), Qt::CaseInsensitive) == 0 ? new PuterStyle : nullptr;
    }
};

} // namespace

#include "puterstyle.moc"
