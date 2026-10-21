import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.DCommon.Widgets
import qs.Widgets

BasePill {
    id: root

    property color idleColor: Theme.widgetTextColor
    property color inhibitColor: Theme.primary

    content: Component {
        Item {
            implicitWidth: icon.width
            implicitHeight: root.contentThickness

            DIcon {
                id: icon
                anchors.centerIn: parent
                name: SessionService.idleInhibited ? "motion_sensor_active" : "motion_sensor_idle"
                size: Theme.barIconSize(root.barThickness, -4, root.barConfig?.maximizeWidgetIcons, root.barConfig?.iconScale)
                color: SessionService.idleInhibited ? inhibitColor : idleColor
            }
        }
    }

    onClicked: SessionService.toggleIdleInhibit()

    Loader {
        id: tooltipLoader
        active: false
        sourceComponent: DTooltip {}
    }

    // Hover-only overlay: acceptedButtons is NoButton so left click (toggle) and
    // right click (duration presets popout, wired up by SurfaceWidgetFactory)
    // still reach BarPill's own MouseArea underneath.
    MouseArea {
        id: tooltipArea

        z: 1
        acceptedButtons: Qt.NoButton
        x: -root.leftMargin
        y: -root.topMargin
        width: root.width + root.leftMargin + root.rightMargin
        height: root.height + root.topMargin + root.bottomMargin
        hoverEnabled: true
        onEntered: {
            if (!root.parentScreen)
                return;
            tooltipLoader.active = true;
            if (!tooltipLoader.item)
                return;
            const tooltipText = SessionService.idleInhibited ? "Sleep inhibited — click to allow" : "Click to prevent sleep";

            if (root.isVerticalOrientation) {
                const localPos = mapToItem(null, width / 2, height / 2);
                const currentScreen = root.parentScreen || Screen;
                const adjustedY = localPos.y + root.minTooltipY;
                const tooltipX = root.axis?.edge === "left" ? (root.barThickness + root.barSpacing + Theme.spacingXS) : (currentScreen.width - root.barThickness - root.barSpacing - Theme.spacingXS);
                const isLeft = root.axis?.edge === "left";
                tooltipLoader.item.show(tooltipText, tooltipX, adjustedY, currentScreen, isLeft, !isLeft);
            } else {
                const isBottom = root.axis?.edge === "bottom";
                const localPos = mapToItem(null, width / 2, 0);
                const currentScreen = root.parentScreen || Screen;

                let tooltipY;
                if (isBottom) {
                    const tooltipHeight = Theme.fontSizeSmall * 1.5 + Theme.spacingS * 2;
                    tooltipY = currentScreen.height - root.barThickness - root.barSpacing - Theme.spacingXS - tooltipHeight;
                } else {
                    tooltipY = root.barThickness + root.barSpacing + Theme.spacingXS;
                }

                tooltipLoader.item.show(tooltipText, localPos.x, tooltipY, currentScreen, false, false);
            }
        }
        onExited: {
            if (tooltipLoader.item) {
                tooltipLoader.item.hide();
            }
            tooltipLoader.active = false;
        }
    }
}
