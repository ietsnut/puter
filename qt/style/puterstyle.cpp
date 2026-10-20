// puter's Qt widget style: Fusion's drawing, with puter's grid. Every menu
// bar, menu item, toolbar button, push button, field, list row, header and
// tab is one 30px module tall; toolbars and menu bars add no frame or margin
// of their own; icons in bars and lists are 16px. Colours, outlines and rules
// are the stylesheet's (theme/qt/puter.qss), not this.

#include <QProxyStyle>
#include <QStyleFactory>
#include <QStylePlugin>
#include <QStyleOption>
#include <QDialog>
#include <QWidget>

namespace {

constexpr int Module = 30;
constexpr int Inset = 8;
constexpr int Icon = 16;

class PuterStyle : public QProxyStyle {
public:
    PuterStyle() : QProxyStyle(QStyleFactory::create(QStringLiteral("Fusion"))) {}

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
