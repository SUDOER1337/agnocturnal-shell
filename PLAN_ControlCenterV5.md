# ControlCenter V5 Redesign Plan

## Goal

Replace the current vertical-card ControlCenter (~440px, `ControlCenterPanel.qml`) and the
separate Settings panel (~840px, `SettingsPanel.qml` + `SettingsPanelWindow.qml`) with a
**single unified V5-style panel**: sidebar + content pane, fixed ~480px, collapsible sidebar,
4 tabs, matching the visual design extracted from the Noctalia v5 C++ rewrite.

---

## Architecture (v5 C++ Reference)

From `src/shell/control_center/` in the v5 branch of `noctalia-dev/noctalia-shell`:

```
RowLayout
├── Sidebar (Flex, column) — surfaceVariant bg, radiusXl
│   └── Tab buttons (ButtonVariant::Tab/TabActive, radiusLg)
│       ├── Home     ("home")
│       ├── Media    ("disc-filled")
│       ├── Audio    ("volume")
│       ├── Display  ("device-desktop")
│       ├── System   ("activity-heartbeat")
│       ├── Network  ("wifi")
│       ├── Bluetooth("bluetooth")
│       ├── Weather  ("weather-cloud-sun")
│       ├── Calendar ("calendar")
│       ├── Notifications ("bell")
│       └── ScreenTime ("hourglass")
└── Content (Flex, column)
    ├── Header (Row: title + per-tab actions + close button)
    └── Tab bodies (stacked, only active visible)
```

**Visual tokens** (from `src/ui/style.h` + `src/ui/palette.h`):

| Token | v5 Value | QML Equivalent |
|-------|----------|---------------|
| Sidebar bg | `SurfaceVariant` with `panelCardOpacity` alpha | `Color.mSurfaceVariant` |
| Content bg | Inherits panel chrome | — |
| Tab button radius | `radiusLg` → `scaled(12px)` | `Style.radiusM` |
| Tab active bg | `TabActive` button variant | `Color.mPrimary` |
| Tab width | full / compact modes | ~180px / ~48px |
| Tab height | `controlHeight` → 38px * scale | `Style.controlHeight * Style.uiScaleRatio` |
| Glyph size | 21px * scale | 21 * `Style.uiScaleRatio` |
| Font (body) | `fontSizeBody` → 14px | `Style.fontSizeM` |
| Font (title) | `fontSizeTitle` → 16px | `Style.fontSizeL` |
| Font weight | Bold for titles/tab labels | `Font.Bold` |
| Card bg | `SurfaceVariant` with opacity | `Color.mSurfaceVariant` |
| Panel padding | `panelPadding` → 14px * scale | `Style.marginL` |
| Tab gap | `spaceXs` → 4px * scale | `Style.marginXS` |
| Border | `borderWidth` → 1px | `Style.borderS` |
| Animations | `animFast` → 100ms | `Style.animationFast` |
| Panel width | 600–780px (per sidebar mode) | ~480px |
| Panel height | `scaled(520px)` | Computed from content |

---

## Phase 1: Scaffolding & Layout

### 1.1 File Structure

```
Modules/Panels/ControlCenterV5/
├── ControlCenterV5Panel.qml      # Main panel (SmartPanel, ~480px)
├── Sidebar.qml                    # Collapsible sidebar navigation
├── Pages/
│   ├── QuickSettingsPage.qml     # Home dashboard (shortcuts + widgets)
│   ├── MediaPage.qml             # Media player (reuses media layout)
│   ├── SystemPage.qml            # System stats (reuses system monitor)
│   └── SettingsPage.qml          # Settings (embeds adapted SettingsContent)
└── Widgets/
    └── (migrate from ControlCenter/Widgets/)
```

### 1.2 Sidebar.qml

Mirror v5 sidebar pattern:
- State: `expanded` (bool, persisted via `ShellState.get/setSettingsSidebarExpanded`)
- Toggle button at top with chevron icon (matching current Settings sidebar)
- 4 nav items: Quick Settings, Media, System, Settings
- Each: icon + label (label hidden when collapsed via opacity animation)
- Active tab: `Color.mPrimary` background + `Color.mOnPrimary` text
- Inactive: `Color.mHover` on hover, else transparent
- Radius: `Style.radiusM`
- Tooltips when collapsed
- Animated width transition: 100ms, `Easing.InOutQuad`
- Search input at top (auto-expands on typing, fuzzy searches settings when on SettingsPage)

### 1.3 ControlCenterV5Panel.qml

Extends `SmartPanel`:
- `preferredWidth: Math.round(480 * Style.uiScaleRatio)`
- `panelContent: RowLayout { Sidebar + ContentArea }`
- `preferredHeight` computed dynamically from content
- Tab switching via internal `currentTab` property (0–3)
- Header row: title label (Primary, Bold, `fontSizeL`) + close button (NIconButton)
- Close button calls `root.close()`
- Panel chrome: inherited from SmartPanel (anchoring, margins, etc.)
- Remove old ControlCenter card-based height computation

### 1.4 ContentArea.qml (inline in panel or separate)

- `StackLayout` or manual visibility toggling between 4 pages
- Only active page visible + loaded
- Fade transition: 100ms opacity
- Header updates based on `currentTab`

---

## Phase 2: Page Content

### 2.1 QuickSettingsPage.qml

Dashboard layout inspired by v5 HomeTab:
- **Top row**: Date/time display + weather summary (one line + icon)
- **User row**: Avatar, user name, session/power button
- **Quick shortcuts grid**: 3-column GridView with toggle widgets
  - Migrate from `ControlCenter/Widgets/*` (AirplaneMode, Bluetooth, DarkMode,
    Network, NightLight, KeepAwake, Notifications, PowerProfile, WallpaperSelector)
  - Each: icon + label + toggle
  - `radiusLg` cards with `Color.mSurfaceVariant` bg
- **Media mini-card**: Compact now-playing (art + track + artist + play/pause)
- **Bottom**: "Open full media player" / "Open settings" buttons

### 2.2 MediaPage.qml

Reuses layout from `MediaPlayerPanel.qml`:
- Album art (large)
- Track title + artist
- Progress bar + time
- Playback controls (prev, play/pause, next, shuffle, repeat)
- Volume slider
- MPRIS player list

### 2.3 SystemPage.qml

Reuses layout from `SystemStatsPanel.qml`:
- CPU graph + usage %
- RAM graph + usage %
- Disk usage
- Network traffic
- Top processes list
- Power profiles toggle

### 2.4 SettingsPage.qml

Embeds adapted `SettingsContent.qml` logic:
- Same tabs model (22+ tabs: General, UI, Bar, Dock, Audio, Display, etc.)
- The sidebar in this page becomes a *second-level sub-navigation*
  - When SettingsPage is active, the main Sidebar's toggle/expand collapses the
    *settings sidebar* instead
  - Search input expands to full settings search (fuzzy search, results list,
    navigate-to-result with highlight overlay)
- All existing Settings tab components reused as-is
- NScrollView wrapper, same keyboard navigation
- Close button still in the CC header (not the settings page)

---

## Phase 3: Wiring & Cleanup

### 3.1 shell.qml Changes

- Replace `ControlCenterPanel` import with `ControlCenterV5Panel`
- Remove `SettingsPanel` and `SettingsPanelWindow` references (line 143)
- CC toggle button now opens `ControlCenterV5Panel`
- "Open Settings" from QuickSettingsPage → switch to Settings tab
- Preserve all existing bar button binding for CC open/close

### 3.2 Remove Old Files

```
Modules/Panels/ControlCenter/ControlCenterPanel.qml
Modules/Panels/Settings/SettingsPanel.qml
Modules/Panels/Settings/SettingsPanelWindow.qml
Modules/Panels/Settings/SettingsContent.qml   (logic absorbed into SettingsPage)
Modules/Panels/Media/MediaPlayerPanel.qml      (absorbed into MediaPage)
Modules/Panels/SystemStats/SystemStatsPanel.qml (absorbed into SystemPage)
```

### 3.3 Config Updates

- `settingsPanelMode` config field → unused, can be deprecated
- Bar "open settings" button target → `openToTab(Settings)` on CC
- Keep `ControlCenterWidgetRegistry` for plugin compatibility

---

## Visual Design Reference (v5 QML Equivalents)

| Element | v5 C++ Code | QML Implementation |
|---------|-------------|-------------------|
| Section card | `applySectionCardStyle` → surfaceVariant + radiusLg + optional border | `NBox { color: Color.mSurfaceVariant; radius: Style.radiusM }` |
| Tab button | `ButtonVariant::Tab`, `radius: radiusLg`, `controlHeight` | Custom Item with MouseArea, radius `Style.radiusM`, height `controlHeight * scale` |
| Tab active | `ButtonVariant::TabActive` | `color: Color.mPrimary` + `NText { color: Color.mOnPrimary }` |
| Sidebar container | `surfaceVariant`, `radiusXl` | `NBox { color: Color.mSurfaceVariant; radius: Style.radiusL }` |
| Title label | `fontSizeTitle` + Bold + Primary color | `NText { pointSize: Style.fontSizeL; color: Color.mPrimary; font.weight: Font.Bold }` |
| Panel gap | `spaceMd` (12px scaled) | `spacing: Style.marginL` |
| Animation | `animFast` (100ms) | `NumberAnimation { duration: Style.animationFast; easing.type: Easing.InOutQuad }` |
| Sidebar toggle | `ControlCenterSidebarMode::Compact` | `Behavior on Layout.preferredWidth` with 100ms animation |
| Shortcut grid | `GridView` with `ShortcutPad` entries | `NListView` or `Flow` / `Grid` of shortcut widgets |

---

## Order of Execution

1. Create directory: `Modules/Panels/ControlCenterV5/Pages/`
2. **Sidebar.qml** — collapsible nav with 4 tabs + search
3. **ControlCenterV5Panel.qml** — SmartPanel with RowLayout layout
4. **QuickSettingsPage.qml** — dashboard with shortcuts, date/time, weather
5. **MediaPage.qml** — wrap existing media content
6. **SystemPage.qml** — wrap existing system stats
7. **SettingsPage.qml** — embed settings with sub-navigation
8. Update **shell.qml** — replace old panels, rewire
9. Remove old panel files
10. Test with `qs -c ~/.config/quickshell/agnocturnal-shell/`
