// puter's Qt widget style: Fusion's drawing, with puter's grid. Every menu
// bar, menu item, toolbar button, push button, field, list row, header and
// tab is one 30px module tall; toolbars and menu bars add no frame or margin
// of their own; icons in bars and lists are 16px. Colours, outlines and rules
// are the stylesheet's (theme/qt/puter.qss), not this. libfm-qt's file
// dialog, every app's through the portal, is pared down and laid on the grid.

#include <QProxyStyle>
#include <QStyleFactory>
#include <QStylePlugin>
#include <QStyleOption>
#include <QComboBox>
#include <QDialog>
#include <QDialogButtonBox>
#include <QEvent>
#include <QLayout>
#include <QPushButton>
#include <QToolBar>
#include <QWidget>

namespace {

constexpr int Module = 30;
constexpr int Inset = 8;
constexpr int Icon = 16;

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
        if (widget->inherits("Fm::FileDialog"))
            widget->installEventFilter(this);
    }

    void unpolish(QWidget *widget) override
    {
        if (widget->inherits("Fm::FileDialog"))
            widget->removeEventFilter(this);
        QProxyStyle::unpolish(widget);
    }

    // The file dialog is pared each time it's shown: its file types are only
    // known by then.
    bool eventFilter(QObject *object, QEvent *event) override
    {
        if (event->type() == QEvent::Show)
            if (auto *dialog = qobject_cast<QDialog *>(object); dialog && dialog->inherits("Fm::FileDialog"))
                pareFileDialog(dialog);
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
        // Main windows lay their parts out flush, bar on bar, so each stays on
        // the grid; dialogs keep Fusion's spacing between their fields.
        case PM_LayoutHorizontalSpacing:
        case PM_LayoutVerticalSpacing:
        case PM_LayoutLeftMargin:
        case PM_LayoutTopMargin:
        case PM_LayoutRightMargin:
        case PM_LayoutBottomMargin:
            if (widget && qobject_cast<const QDialog *>(widget->window()))
                return QProxyStyle::pixelMetric(metric, option, widget);
            return 0;
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
            return 10;
        case PM_TabBarTabHSpace:
            return 2 * Inset;
        case PM_TabBarTabVSpace:
            return 0;
        case PM_HeaderMargin:
            return Inset;
        default:
            return QProxyStyle::pixelMetric(metric, option, widget);
        }
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
        case CT_HeaderSection:
        case CT_ItemViewItem:
            return {size.width(), Module};
        case CT_TabBarTab:
            return {size.width(), Module};
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
