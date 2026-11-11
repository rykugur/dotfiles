import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var percentage: PluginService.getGlobalVar("logitechMouseBattery", "percentage", null)

    Connections {
        target: PluginService
        function onGlobalVarChanged(pluginId, varName) {
            if (pluginId === "logitechMouseBattery" && varName === "percentage")
                root.percentage = PluginService.getGlobalVar(pluginId, varName, null);
        }
    }

    horizontalBarPill: Component {
        Grid {
            columns: root.isVertical ? 1 : 2
            spacing: Theme.spacingXS
            verticalItemAlignment: Grid.AlignVCenter

            DIcon {
                name: "mouse"
                size: root.iconSize
                color: Theme.widgetTextColor
            }
            StyledText {
                text: root.percentage === null ? "—" : root.percentage + "%"
                font.pixelSize: root.textSize
                color: Theme.widgetTextColor
            }
        }
    }

    verticalBarPill: horizontalBarPill
}
