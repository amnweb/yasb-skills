pragma ComponentBehavior: Bound

// A complete YASB 3 widget, written the way YASB's own widgets are. Save it as
// %USERPROFILE%\.config\yasb\widgets\<Name>\<Name>.qml, with the folder and the file named the same, and add <Name> to a
// bar in config.yaml. This one shows the CPU usage, opens a popup with the busiest processes, and has a menu.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Yasb
import Yasb.Bar
import Yasb.Common
import Yasb.Themes

Item {
    id: root

    component Icons: QtObject {
        property string cpu
        property string more
    }

    // Every option a user may change, at the top, each with its default. Colours and fonts start from the theme, so
    // the widget follows the user's theme and light and dark mode until they set a value here.
    component Settings: QtObject {
        required property Theme theme

        // Milliseconds between two readings
        property int updateInterval: 2000
        // The usage, in percent, from which the label turns to warnColor
        property real warnAt: 85
        // {usage} is the usage in percent
        property string label: "{usage}%"
        property bool tooltip: true
        // Keys that open the popup, such as "alt+shift+c"; "" for none
        property string hotkey: ""
        property color textColor: theme.colors.text
        property color warnColor: theme.colors.critical
        // Labels on the bar take the bar's font; parts set here replace the bar's
        property font font
        property font iconFont
        iconFont.family: theme.bar.iconFont.family
        iconFont.weight: theme.bar.iconFont.weight
        iconFont.variableAxes: theme.bar.iconFont.variableAxes
        property int iconSize: theme.bar.iconFont.pixelSize
        readonly property Icons icons: Icons {
            cpu: "\ueea1"
            more: "\ue712"
        }
        property int popupWidth: 280
        // The popup: the theme's, unless set here
        property color popupColor: theme.popup.background
        property color popupBorderColor: theme.popup.border
        property color popupTextColor: theme.colors.text
        property color popupSecondaryTextColor: theme.colors.textSecondary
        property color popupDividerColor: theme.colors.divider
        property color popupHoverColor: theme.colors.hover
        property real popupRadius: theme.popup.radius
        property real popupGap: theme.popup.gap
        property int popupOpenDuration: theme.popup.openDuration
        property int popupCloseDuration: theme.popup.closeDuration
        // Text in the popup: the theme's font family, in this widget's sizes
        property font popupFont
        popupFont.family: theme.popup.font.family
        popupFont.pixelSize: 13
        property font popupTitleFont
        popupTitleFont.family: theme.popup.font.family
        popupTitleFont.pixelSize: 16
        popupTitleFont.weight: 600
        property font popupIconFont
        popupIconFont.family: theme.popup.iconFont.family
        popupIconFont.weight: theme.popup.iconFont.weight
        popupIconFont.variableAxes: theme.popup.iconFont.variableAxes
        // The menu: the theme's, unless set here
        property int menuWidth: 180
        property color menuColor: theme.menu.background
        property color menuBorderColor: theme.menu.border
        property color menuTextColor: theme.colors.text
        property real menuRadius: theme.menu.radius
        property font menuFont: theme.menu.font
        property int menuOpenDuration: theme.menu.openDuration
    }

    // YASB sets the bar the widget is in; its theme is the bar's
    required property BarBase bar
    readonly property Theme theme: bar.theme
    readonly property Settings settings: Settings {
        theme: root.theme
    }

    readonly property string edge: bar.edge
    readonly property real usage: monitor.data.percent.total

    // Next to the widget on the bar's side away from the screen edge, kept on the screen
    function placePopup() {
        const start = mapToGlobal(0, 0)
        const gap = settings.popupGap
        let px = edge === "left" ? start.x + width + gap
            : edge === "right" ? start.x - popup.width - gap : start.x + (width - popup.width) / 2
        let py = edge === "top" ? start.y + height + gap
            : edge === "bottom" ? start.y - popup.height - gap : start.y + (height - popup.height) / 2
        const screen = root.Screen
        px = Math.max(screen.virtualX + 8, Math.min(px, screen.virtualX + screen.width - popup.width - 8))
        py = Math.max(screen.virtualY + 8, Math.min(py, screen.virtualY + screen.desktopAvailableHeight - popup.height - 8))
        popup.x = Math.round(px)
        popup.y = Math.round(py)
    }

    function togglePopup() {
        if (popup.visible) {
            popup.close()
            return
        }
        busiest.run()
        placePopup()
        popup.open()
    }

    // Opens the menu under its button, right edges lined up so it stays over the popup, or closes it when open
    function toggleMenu(menu: Menu, button: Item) {
        if (menu.visible) {
            menu.close()
            return
        }
        menu.popup(button, button.width - menu.width, button.height)
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: qsTr("CPU %1%").arg(usage.toFixed(0))
    Accessible.onPressAction: togglePopup()
    Keys.onReturnPressed: togglePopup()
    Keys.onSpacePressed: togglePopup()

    // The popup is a separate window, so hide it when the widget is destroyed
    Component.onDestruction: popup.hide()

    CpuMonitor {
        id: monitor

        updateInterval: root.settings.updateInterval
    }

    Process {
        id: busiest

        command: ["powershell", "-NoProfile", "-Command",
            "Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 -ExpandProperty ProcessName"]
    }

    Hotkey {
        keys: root.settings.hotkey
        onActivated: root.togglePopup()
    }

    // Hides the popup with the bar, and keeps it next to the widget when the bar moves or the popup grows
    Connections {
        target: root.Window.window
        function onVisibleChanged() {
            if (!root.Window.window?.visible)
                popup.hide()
        }
        function onXChanged() { if (popup.visible) root.placePopup() }
        function onYChanged() { if (popup.visible) root.placePopup() }
    }

    Connections {
        target: popup
        function onHeightChanged() { if (popup.visible) root.placePopup() }
    }

    Row {
        id: row

        height: parent.height
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.settings.icons.cpu
            textFormat: Text.PlainText
            color: root.settings.textColor
            font.family: root.settings.iconFont.family
            font.weight: root.settings.iconFont.weight
            font.variableAxes: root.settings.iconFont.variableAxes
            font.pixelSize: root.settings.iconSize
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.settings.label.replace("{usage}", root.usage.toFixed(0))
            textFormat: Text.PlainText
            color: root.usage >= root.settings.warnAt ? root.settings.warnColor : root.settings.textColor
            font: root.settings.font
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePopup()
    }

    ToolTip {
        popupType: Popup.Window
        visible: root.settings.tooltip && area.containsMouse && !popup.visible
        delay: 400
        text: qsTr("CPU usage: %1%").arg(root.usage.toFixed(1))
        // Away from the bar's edge
        y: root.edge === "bottom" ? -implicitHeight - root.settings.popupGap : root.height + root.settings.popupGap
    }

    BackdropPopup {
        id: popup

        property real reveal: 0

        title: "CPU"
        width: root.settings.popupWidth
        height: popupContent.implicitHeight
        anchor: root
        font: root.settings.popupFont
        theme: root.theme
        backdropItem: surface
        enter: NumberAnimation { target: popup; property: "reveal"; to: 1; duration: root.settings.popupOpenDuration; easing.type: Easing.OutCubic }
        exit: NumberAnimation { target: popup; property: "reveal"; to: 0; duration: root.settings.popupCloseDuration; easing.type: Easing.InCubic }
        onVisibleChanged: {
            if (!visible)
                reveal = 0
        }

        Rectangle {
            id: surface

            anchors.fill: parent
            radius: root.settings.popupRadius
            color: root.settings.popupColor
            border.width: 1
            border.color: root.settings.popupBorderColor
            opacity: popup.reveal
            scale: 0.85 + popup.reveal * 0.15
            transformOrigin: root.edge === "bottom" ? Item.Bottom : Item.Top

            ColumnLayout {
                id: popupContent

                width: parent.width
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 10
                    Layout.topMargin: 12
                    Layout.bottomMargin: 10

                    Text {
                        Layout.fillWidth: true
                        text: "CPU"
                        textFormat: Text.PlainText
                        color: root.settings.popupTextColor
                        font: root.settings.popupTitleFont
                    }

                    Item {
                        id: moreButton

                        implicitWidth: 28
                        implicitHeight: 28
                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("More")
                        Accessible.onPressAction: root.toggleMenu(menu, moreButton)

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: moreArea.containsMouse ? root.settings.popupHoverColor : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.settings.icons.more
                            textFormat: Text.PlainText
                            color: root.settings.popupTextColor
                            font.family: root.settings.popupIconFont.family
                            font.weight: root.settings.popupIconFont.weight
                            font.variableAxes: root.settings.popupIconFont.variableAxes
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: moreArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleMenu(menu, moreButton)
                        }
                    }
                }

                // The header's bottom line, which the loading bar runs along
                LoadingLine {
                    Layout.fillWidth: true
                    running: busiest.running
                    trackColor: root.settings.popupDividerColor
                }

                Text {
                    Layout.fillWidth: true
                    Layout.margins: 16
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    text: busiest.running ? qsTr("Reading...") : busiest.error || busiest.output.trim()
                    color: root.settings.popupSecondaryTextColor
                    font: root.settings.popupFont
                }
            }

            Menu {
                id: menu

                // A window of its own, so it shows whole even past the popup's edges
                popupType: Popup.Window
                // A press on the button that opened it is left to the button, which closes it again
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
                // Its window is reused, and Windows would show it under the popup raised since
                onAboutToShow: contentItem.Window.window?.raise()
                enter: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: root.settings.menuOpenDuration; easing.type: Easing.OutCubic }
                }
                topInset: 0
                leftInset: 0
                rightInset: 0
                bottomInset: 0
                font: root.settings.menuFont
                // Active and inactive only, so disabled items keep the style's dimmed colours
                palette.active.text: root.settings.menuTextColor
                palette.inactive.text: root.settings.menuTextColor

                background: Rectangle {
                    implicitWidth: root.settings.menuWidth
                    radius: root.settings.menuRadius
                    color: root.settings.menuColor
                    border.color: root.settings.menuBorderColor
                }

                MenuItem {
                    text: qsTr("Refresh")
                    onTriggered: busiest.run()
                }

                MenuItem {
                    text: qsTr("Task Manager")
                    onTriggered: {
                        popup.close()
                        launcher.start()
                    }
                }
            }
        }
    }

    Process {
        id: launcher

        command: "taskmgr"
    }
}
