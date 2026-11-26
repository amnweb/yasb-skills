---
name: yasb
description: Writes, fixes and packs widgets, themes and layouts for YASB 3, the Qt Quick status bar for Windows. Use when the user asks for a YASB widget or a QML widget for the YASB bar, a YASB theme or layout, the bars and widgets in YASB's config.yaml, or an addon with a manifest.json for yasb-addons. Not for YASB 2 widgets, which are Python and CSS.
license: MIT
compatibility: YASB 3.0 or newer, on Windows. scripts/check.py compiles QML only with the YASB repository and its Python packages.
---

# YASB 3: widgets, themes and layouts

YASB runs from the user's config folder, `%USERPROFILE%\.config\yasb`, or the folder in `YASB_CONFIG_HOME`.
`config.yaml` names the bars, the layout and theme each one uses, and the widgets in each of its slots. Widgets, themes
and layouts are QML files in that folder. Python services, from `import Yasb`, read the PC for the widgets.

## Read first, for the job

| Job | Read | Start from |
| --- | --- | --- |
| A widget | [guide-writing-widgets.md](references/guide-writing-widgets.md), then the API file of each type it uses, found in [api.md](references/api.md) | [Widget.qml](assets/Widget.qml) |
| A theme | [guide-themes.md](references/guide-themes.md), [type-theme.md](references/api/type-theme.md) | [theme.qml](assets/theme.qml) |
| A layout | [guide-layouts.md](references/guide-layouts.md), and the Bar, BarBase, IslandBar and WidgetSlot files in [api.md](references/api.md) | [layout.qml](assets/layout.qml), [layout-slots.qml](assets/layout-slots.qml) |
| Options of one of YASB's own widgets | [guide-widgets.md](references/guide-widgets.md) | `yasbc addons install <Widget>` |
| Bars and widgets in config.yaml | [guide-configuration.md](references/guide-configuration.md) | |
| Sharing as an addon | [guide-addons.md](references/guide-addons.md) and [Addons](#addons) below | |
| Something doesn't load | [guide-troubleshooting.md](references/guide-troubleshooting.md) | |

Read only the API files of the types you use. A property or function that isn't in its API file doesn't exist: don't
guess one from general Qt knowledge or from YASB 2.

## Rules

Each one is a mistake that breaks a widget or makes it look wrong.

1. **The bar.** A widget's root declares `required property BarBase bar` (`import Yasb.Bar`), and its theme is
   `bar.theme`. The bar has no `textColor`, `font` or `iconFont`: they are in the theme.
2. **Options.** Every option goes in `component Settings: QtObject { required property Theme theme ... }` at the top of
   the widget, with its default, and colours and fonts default to the theme: `theme.colors.*`, `theme.bar.*`,
   `theme.popup.*`, `theme.menu.*`. No hard-coded colours or font families. Options are never set in `config.yaml`,
   which only lists widget names under each slot.
3. **Popups.** `BackdropPopup` (`import Yasb.Common`) needs `theme:`. Without it the widget doesn't load. Also set
   `font`, `anchor` (the widget, so a click on it closes the popup instead of opening another), `backdropItem`, and
   `enter` and `exit` animations. Place it with a `placePopup()` like the template's, and add
   `Component.onDestruction: popup.hide()`, as the popup is a separate window. A `Shape` in the popup whose path never
   changes needs `path: popup.visible ? ... : ""`, or it's blank after the popup reopens.
4. **Menus and combo boxes in a popup.** `popupType: Popup.Window`, `closePolicy: Popup.CloseOnEscape |
   Popup.CloseOnPressOutsideParent`, `onAboutToShow: contentItem.Window.window?.raise()`, and open it from its button
   with a toggle that lines up the right edges, as in the template. With `Popup.Item` the menu is cut at the popup's
   edge. With the default closePolicy a click on its button closes it and opens it again. A `ComboBox` in a popup gets
   `popup.popupType: Popup.Window`.
5. **Ids.** Never give an id the name of a property of an item it is used inside. In a `MenuItem`, `display` means
   `MenuItem.display`, not an object with the id `display`. In a `BackdropPopup`, `content` is its own property. qmllint
   reports these as `id-shadows-member`.
6. **Icons.** Glyphs are Segoe Fluent Icons, written in QML as `"\uXXXX"` escape text. Never paste the raw character,
   which is invisible and breaks when the file is edited. Check the saved file holds a backslash and a `u`.
7. **Text.** On the bar use `Label` from QtQuick.Controls, which takes the bar's font. In a popup set each `Text`'s font
   and colour from the settings.
8. **Services cost.** Services that scan or poll have a setting such as `watching` or `active`. Bind it to
   `popup.visible` or `root.visible`, so they work only while seen. Lists from services are models: a delegate declares
   each row field as `required property`, and a function that acts on a row takes that row's field at the moment of the
   call.
9. **Files.** A widget is `widgets\<Name>\<Name>.qml`, folder and file named the same, and `config.yaml` lists `<Name>`.
   An addon is `widgets\<login>.<name>\<Name>.qml`, listed by its id. Other files the widget needs sit beside it and
   are found with `Qt.resolvedUrl("file")`. Never edit YASB's own files in its install folder: `yasbc addons install
   <Widget>` gives the user a copy to change.
10. **YASB 2.** YASB 2 widgets are Python with CSS, and its config.yaml names widgets with a `type` such as
    `"yasb.clock.ClockWidget"`. None of this skill applies to them, and YASB 3 can't read a YASB 2 config: say so.

## Check your work

1. **Compile.** With the YASB repository and its packages (`pip install -e <repo>`), run `scripts/check.py` from this
   skill's folder (in Claude Code, `${CLAUDE_SKILL_DIR}/scripts/check.py`):

   ```
   python scripts/check.py <widget folder or .qml file> --yasb <path to the YASB repository>
   ```

   It compiles every QML file against YASB's types without running it, and checks `manifest.json` and the file names.
   Without `--yasb` it checks only the manifest and the files.
2. **Run.** While `watch: true` (the default) and YASB runs, saving a widget, theme or layout loads it again. Any QML
   error goes to `yasb.log` in the config folder (`yasbc log` follows it). After saving, read the new lines and fix
   until none name the file. Ask the user before starting, restarting or closing YASB.
3. **qmllint**, when Qt is installed: `qmllint --json - <file>` lists more than its plain output. Imports from
   `import Yasb` need YASB's generated type information to be checked.

## Addons

An addon is a widget, theme, layout or config shared through yasb-addons or a GitHub repository. Before sharing:

- `manifest.json` beside the QML file: `id` (`<github login>.<name>`, lower case, the name a letter then letters or
  digits), `title` (up to 50 characters), `description` (one line, up to 200), `version` (a whole number from 1, raised
  for each update), `released` (`YYYY-MM-DD`, not in the future), and `type` (`widget`, `theme`, `layout` or `config`)
  for an addon installed from its own repository.
- The QML file is named after the part of the id after the dot, in any case: `amnweb.clock` is `Clock.qml`.
- No `.exe` or `.dll` files. Files and folders whose names start with a dot are left out.
- For yasb-addons: a ZIP of the folder, a square screenshot of at least 800x800, and an About text for the form,
  as [guide-addons.md](references/guide-addons.md) describes.
- Say in the About what the addon reads, sends or runs, such as a token file or a web service.
