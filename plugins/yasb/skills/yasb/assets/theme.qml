// A YASB 3 theme. Save it as %USERPROFILE%\.config\yasb\themes\<name>.qml and set theme: <name> in config.yaml, for
// every bar, or under one bar for that bar only. It sets only what it changes: every other value keeps YASB's own.
// references/api/type-theme.md lists every value with its default.
import QtQuick
import Yasb.Themes

Theme {
    // dark is true while Windows is in dark mode; "dark ? A : B" is A in dark mode and B in light mode
    colors {
        accent: "#4CC2FF"
        background: dark ? "#1C1C1C" : "#F3F3F3"
        critical: dark ? "#FF99A4" : "#C42B1C"
    }

    bar {
        // See through it, so the blur of backdrop: true in config.yaml shows
        background: Qt.alpha(colors.background, 0.85)
        // A part set here replaces only that part of the font
        font.family: "Segoe UI Variable Text"
        font.pixelSize: 14
    }

    popup {
        radius: 12
        openDuration: 150
    }

    menu {
        font.pixelSize: 14
    }
}
