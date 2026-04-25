import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

NIconButtonHot {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    readonly property string screenName: screen?.name ?? ""

    icon: "crosshair"
    tooltipText: "Screen Toolkit"

    onClicked: {
        if (pluginApi) {
            pluginApi.togglePanel(screen, root);
        }
    }
}
