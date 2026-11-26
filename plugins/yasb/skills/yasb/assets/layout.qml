// A YASB 3 layout: the bar's own look. Save it as %USERPROFILE%\.config\yasb\layouts\<name>.qml and set
// layout: <name> under a bar in config.yaml. Bar has three slots for config.yaml's widgets: left, center and right on a
// bar at the top or bottom, top, center and bottom at the left or right. For slots of your own, see layout-slots.qml.
import QtQuick
import Yasb.Bar

Bar {
    id: bar

    color: theme.bar.background
    border.width: 1
    border.color: theme.bar.border
    // Square while a window is maximized on the bar's screen, rounded otherwise
    radius: hasMaximizedWindow ? 0 : 8
    padding: 12
    spacing: 12

    // Anything inside the root is drawn on the bar; parent: bar.background draws it under the widgets.
    // A line of the accent colour along the side away from the screen edge
    Rectangle {
        parent: bar.background
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: bar.edge === "bottom" ? parent.top : undefined
        anchors.bottom: bar.edge === "bottom" ? undefined : parent.bottom
        height: 2
        color: bar.theme.colors.accent
        visible: !bar.vertical
    }
}
