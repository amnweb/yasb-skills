# YASB 3 widgets, themes and layouts

This folder is a YASB 3 config folder. `config.yaml` names the bars, the layout and theme each one uses, and the widgets
in each slot. Widgets (`widgets\<Name>\<Name>.qml`), themes (`themes\<name>.qml`) and layouts (`layouts\<name>.qml`) are
QML files. Python services, from `import Yasb`, read the PC for the widgets.

Before writing anything, read the YASB skill on GitHub:
https://github.com/amnweb/yasb-skills/tree/main/plugins/yasb/skills/yasb

- `SKILL.md`: which reference to read for each job, the rules, and how to check the work.
- `references/api.md`: every service and QML type, with a file each. A property or function that isn't in its file
  doesn't exist.
- `assets/Widget.qml`: a complete widget to start from.

The rules that break a widget most often:

1. The widget's root declares `required property BarBase bar` (`import Yasb.Bar`). Its theme is `bar.theme`.
2. Every option goes in `component Settings: QtObject { required property Theme theme ... }`, with colours and fonts
   from the theme. Options are never in `config.yaml`.
3. `BackdropPopup` needs `theme:`, or the widget doesn't load.
4. Menus in a popup use `popupType: Popup.Window` and
   `closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent`.
5. Never name an id after a property of the item it's used in, such as `display` inside a `MenuItem`.
6. Glyphs are `"\uXXXX"` escape text, never the raw character.

After saving a file, read the new lines of `yasb.log` in this folder, and fix until none name the file. Ask before
starting or closing YASB.
