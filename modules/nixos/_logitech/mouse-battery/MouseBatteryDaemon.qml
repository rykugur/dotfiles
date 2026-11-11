import QtQuick
import qs.Common
import qs.Services
import "Battery.js" as Battery

QtObject {
    id: root

    property string pluginId: ""
    property var pluginService: null
    readonly property var queryCommand: SettingsData.getPluginSetting(pluginId, "command", [])

    // One daemon shares the reading across every monitor's bar widget.
    property Timer poller: Timer {
        interval: 60000
        repeat: true
        triggeredOnStart: true
        running: root.queryCommand.length > 0
        onTriggered: Proc.runCommand(root.pluginId, root.queryCommand, (output, exitCode) => {
            PluginService.setGlobalVar(root.pluginId, "percentage", Battery.parseBattery(output, exitCode));
        }, 0, 10000, root)
    }

    Component.onDestruction: {
        Proc.release(pluginId);
        PluginService.setGlobalVar(pluginId, "percentage", null);
    }
}
