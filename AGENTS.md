# AGENTS.md — Agnoctural Shell

**Agnoctural** is an independent fork of Noctalia Shell v4: a minimal QML-based Wayland desktop shell built with Quickshell.

---

## Project Type & Entry

- **Language**: QML + Qt6
- **Framework**: Quickshell (via `noctalia-qs` fork)
- **Main entry**: `shell.qml` (ShellRoot component)
- **Package manager**: Nix flakes
- **Config path**: `~/.config/agnocturnal/` (not `~/.config/noctalia/`)

---

## Build & Test Commands

### Dev Environment
```bash
nix develop            # Enter dev shell with quickshell, qt6, and all tools
nix flake show         # Show available derivations
```

### Build
```bash
nix build              # Build the shell package
```

### Format & Lint
```bash
./Scripts/dev/qmlfmt.sh       # Format all QML files (uses qmlformat from qt6-declarative)
python3 Scripts/dev/build-settings-search-index.py  # Rebuild settings search index
```

### Pre-commit Hooks
Lefthook runs automatically on `git commit`:
1. **QML formatting** — auto-fixes formatting in all `.qml` files
2. **Settings index** — rebuilds `Assets/settings-search-index.json` from config defaults

To manually test:
```bash
lefthook run pre-commit
```

---

## Project Structure

### `Commons/`
Shared utilities imported as `qs.Commons`:
- **Color.qml** — Color manipulation and theming
- **I18n.qml** — Internationalization strings
- **Settings.qml** — Central settings manager
- **ShellState.qml** — Shell-wide state (loaded, focused monitors, etc.)
- **Style.qml** — Design tokens and spacing
- **Logger.qml** — Debug logging
- **Icons.qml**, **IconsTabler.qml** — Icon sets
- **Keybinds.qml** — Keyboard shortcut binding system
- **Time.qml** — Time and calendar utilities

### `Modules/`
UI components — imported as `qs.Modules.*`:
- **Bar/** — Top/bottom taskbar
- **Dock/** — Application dock
- **LockScreen/** — Lock screen
- **Notification/** — Notification center
- **OSD/** — Volume/brightness overlay
- **Panels/** — Settings, Launcher, and other panels (21+ submodules)
- **DesktopWidgets/** — Floating widgets
- **Toast/** — Toast notifications
- **Background/** — Wallpaper handling
- **MainScreen/** — Primary screen layout

### `Services/`
Backend logic — imported as `qs.Services.*`:
- **Agnocturnal/** — Fork-specific (config, migrations)
- **Theming/** — Color schemes, wallpaper colors, dark mode
- **Control/** — System controls (power, audio, brightness)
- **Networking/** — Network status and WiFi
- **Hardware/** — System info, battery
- **Keyboard/** — Keyboard layout
- **Compositor/** — Wayland compositor detection and interaction
- **UI/** — UI state (focus, monitors, window hints)
- **Power/** — Power management
- **Media/** — Media player controls
- **Location/** — Geolocation

### `Assets/`
- **settings-default.json** — Factory defaults for all shell settings
- **settings-search-index.json** — Pre-built index for settings search (auto-rebuilt by pre-commit)
- **settings-widgets-default.json** — Default desktop widget configs
- **Launcher/emoji.json** — Emoji data
- All `.json` files are **auto-formatted** by the dev shell

### `Scripts/dev/`
- **qmlfmt.sh** — QML formatter wrapper (parallel, multicore)
- **build-settings-search-index.py** — Regenerate settings search index (run before commit)
- **colorscheme-registry.sh** — Manage color scheme registry
- **i18n-{push,pull}.sh** — Translation sync
- **notifications-test*.sh** — Send test notifications for manual QA
- **shaders-compile.sh** — Compile QML shader effects

---

## Environment Variables

**Development**:
- `AGNOCTURNAL_DEBUG=1` — Enable debug logging in shell
- `QS_CONFIG_PATH` — Override config directory (defaults to `~/.config/agnocturnal/`)
- `QT_LOGGING_RULES` — Control Qt debug output (used by qmlformat to suppress noise)

**Build**:
- `QMLFMT_JOBS` — Parallel jobs for `qmlfmt.sh` (defaults to `nproc`)
- `QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi,vdpau` — Hardware video decode
- `QT_FFMPEG_ENCODING_HW_DEVICE_TYPES=vaapi,vdpau` — Hardware video encode

---

## QML Import Namespace

All modules use the `qs.*` import prefix:
```qml
import qs.Commons
import qs.Services.Theming
import qs.Modules.Bar
```

This is managed by Quickshell's module system, not a standard `qmldir`. **Do not rename or reorganize modules** without updating `shell.qml` imports.

---

## Runtime Dependencies

Packaged via Nix, but agents should know these are required for full functionality:
- `brightnessctl` — Brightness control
- `cliphist` — Clipboard history
- `ddcutil` — Monitor DDC control
- `wlsunset` — Automatic color temperature
- `wl-clipboard` — Clipboard access
- `wlr-randr` — Monitor configuration
- `imagemagick` — Image processing (wallpaper colors)
- `wget` — HTTP downloads (wallhaven integration)
- `python3` — Runtime scripts and calendaring (optional: pygobject3)

---

## Important Notes

### Config Migration
- **Old Noctalia**: `~/.config/noctalia/` → **New Agnoctural**: `~/.config/agnocturnal/`
- Environment variable: `AGNOCTURNAL_CONFIG_DIR`, `AGNOCTURNAL_CACHE_DIR`
- Color scheme names changed: `"Noctalia (default)"` → `"Agnoctural (default)"`

### Nix Build Exclusions
These files are excluded from the final package build (see `nix/package.nix`):
- `.github/`, `LICENSE`, `README.md`, `CREDITS.md`
- `flake.nix`, `flake.lock`, `shell.nix`, `lefthook.yml`, `CLAUDE.md`
- `Assets/Screenshots/`, `Scripts/dev/`, `nix/`

Only QML source, configs, and assets are packaged.

### Wayland Compositor Support
Agnoctural detects and adapts to the running compositor:
- **Niri** — Native
- **Hyprland** — Via Hyprcursor/Hyprctl
- **Sway** — Via wlr-randr
- **Labwc** — Minimal support
- **MangoWC** — Minimal support

---

## Testing & Validation

### Shell Load Test
To test the shell compiles and loads without errors:
```bash
# Kill existing instance first (or use --allow-duplicate to run alongside)
pkill -f "quickshell.*agnocturnal-shell" 2>/dev/null
qs -c ~/.config/quickshell/agnocturnal-shell/
```
Look for `Configuration Loaded` in stdout — it confirms clean startup. `ERROR` lines indicate load failures (usually missing types, bad imports, or corrupted QML files).

### Notification Testing
```bash
./Scripts/dev/notifications-test.sh          # Send test notifications
./Scripts/dev/notifications-test-replace.sh  # Test notification replacement
```

### QML Lint
```bash
nix develop  # Get access to qmllint (qt6)
qmllint <file.qml>
```

### Format Validation
After changes, always run:
```bash
./Scripts/dev/qmlfmt.sh
python3 Scripts/dev/build-settings-search-index.py
git add -A && lefthook run pre-commit
```

---

## References

- **Upstream (Original Noctalia)**: https://github.com/noctalia-dev/noctalia-shell
- **Quickshell Documentation**: https://quickshell.org/
- **Fork Status**: See `FORK_NOTES.md` for maintenance scope and relationship to Noctalia v5
- **Configuration**: `FORK_NOTES.md` explains config migration from Noctalia v4

---

## Known Constraints

1. **Quickshell Dependency**: Agnoctural depends on the `noctalia-qs` fork. If unmaintained, shell cannot be updated beyond current Quickshell capabilities.
2. **QML Only**: No C++ rewrites; architecture is QML-based by design.
3. **Wayland Only**: X11 is not supported.
4. **Not a Full DE**: Handles shell UI only—file manager, settings daemon, window manager, greeter are external.
