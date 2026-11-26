// A YASB 3 layout with slots of its own, for a bar at the top or bottom. BarBase has no slots: each WidgetSlot shows
// the widgets config.yaml lists under its name. config.yaml for this one:
//
//   bars:
//     yasb-bar:
//       layout: two-ends
//       widgets:
//         start:
//           - ActiveWindow
//         end:
//           - Clock
import QtQuick
import Yasb.Bar

BarBase {
    color: theme.bar.background
    radius: 8

    WidgetSlot {
        name: "start"
        height: parent.height
    }

    WidgetSlot {
        name: "end"
        anchors.right: parent.right
        height: parent.height
    }
}
