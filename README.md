# Agnoctural Shell

> **Fork Notice:** Agnoctural is an independent fork of [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell), which was discontinued after v4 in favor of a C++ rewrite (v5). This fork is maintained as a standalone project for continued use and development.

**_quiet by design_**

A beautiful, minimal desktop shell for Wayland built on [Quickshell](https://quickshell.org/) (Qt/QML) with a warm lavender aesthetic that you can easily customize to match your vibe.

---

## ✨ Key Features

- 🪟 **Native support** for Niri, Hyprland, Sway, Scroll, Labwc and MangoWC
- 🎨 **Extensive theming** with predefined color schemes and automatic color generation from your wallpaper
- 🖼️ **Wallpaper management** with Wallhaven integration
- 🔔 **Notification system** with history and Do Not Disturb
- 🖥️ **Multi-monitor support**
- 🔒 **Lock screen** with customizable options
- 🧩 **Desktop widgets** (clock, media player and more)
- 💡 **OSD** for volume and brightness
- 🔌 **Plugin system** for extending functionality
- 🪄 **Setup wizard** for first-time users
- ⚡ **Built on Quickshell** for performance

---

## 📋 Requirements

- **Wayland compositor** (see supported compositors below)
- **Quickshell**: [noctalia-qs](https://github.com/noctalia-dev/noctalia-qs) (the fork maintained for Noctalia v4)
- **Additional dependencies**: See documentation or nix files

---

## 🖥️ Supported Wayland Compositors

Agnoctural provides native support for:
- **Niri** — Scrollable-tiling compositor
- **Hyprland** — Dynamic tiling Wayland compositor
- **Sway** — i3-like Wayland compositor
- **Scroll** — Minimalist tiling compositor
- **Labwc** — Label-based window compositor
- **MangoWC** — Mango window compositor

Other Wayland compositors may work but could require additional configuration for compositor-specific features.

---

## 🚀 Getting Started

### Installation

**Via Nix (recommended):**
```bash
nix run github:SUDOER1337/agnocturnal-shell
```

**Via NixOS (home-manager):**
Add to your home-manager configuration:
```nix
programs.agnoctural-shell = {
  enable = true;
};
```

For other Linux distributions, refer to the installation instructions in the repository documentation.

### Configuration

Configuration files are stored in `~/.config/agnocturnal/`:
- `settings.json` — Main settings file
- `colors.json` — Current color scheme (auto-generated)
- `colorschemes/` — Downloaded color schemes

### Environment Variables

Control behavior via environment variables:
- `AGNOCTURNAL_CONFIG_DIR` — Override config directory (default: `~/.config/agnocturnal/`)
- `AGNOCTURNAL_CACHE_DIR` — Override cache directory (default: `~/.cache/agnocturnal/`)
- `AGNOCTURNAL_DEBUG` — Enable debug logging (set to `1`)

---

## 📖 Documentation & Help

Since this is a fork maintained for personal use, documentation is limited. However, most Noctalia v4 documentation still applies:

- **Original Noctalia Docs**: [docs.noctalia.dev](https://docs.noctalia.dev)
- **GitHub Discussions/Issues**: Use the issue tracker in this repo
- **Discord**: Original Noctalia community (may still be active)

---

## 🔧 Scope: Desktop Shell, Not Desktop Environment

Agnoctural is a **desktop shell**, not a full desktop environment. It provides the visual layer (bars, panels, notifications, dock, widgets) that sits on top of your Wayland compositor but intentionally stays within that boundary.

### What Agnoctural does:
- Status bar, panels, application launcher
- Notifications and notification history
- Lock screen and idle management
- On-screen display (OSD) for volume/brightness
- Theming and wallpaper management
- Desktop widgets
- Multi-monitor support

### What Agnoctural doesn't do:
- **File management** — use a file manager application
- **Display/login greeter** — managed by system/display manager
- **Window management & tiling** — compositor responsibilities
- **System login** — handled by system services

---

## 🛠️ Development

This is a fork maintained for independent use. For development setup:

1. Clone the repository
2. Install dependencies (see `flake.nix` for Nix-based setup)
3. Run with: `nix flake show`
4. Make changes and test locally

### Building from source:
```bash
nix build
```

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 💜 Credits & Attribution

**Agnoctural** is forked from [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell).

**Current Maintainer:** Nullfjord (SUDOER1337)

**Original Noctalia Project:** Created and maintained by the Noctalia team (now focused on v5 C++ rewrite)

Special thanks to:
- The [Noctalia community](https://github.com/noctalia-dev/noctalia-shell/graphs/contributors) for the original foundation
- The [Quickshell](https://quickshell.org/) project for the excellent Qt/QML framework
- All contributors and community members

---

## 📄 License

MIT License - see [LICENSE](./LICENSE) for details.

---

## ⚠️ Important Notes

- This is an **independent fork** maintained for personal use
- Original Noctalia v5 development has moved to C++ and is no longer QML-based
- This fork is based on Noctalia v4 and remains QML-based with Quickshell
- For the official Noctalia v5 project, see [noctalia.dev](https://noctalia.dev)

---

## 🔗 Links

- **GitHub (this fork)**: https://github.com/SUDOER1337/agnocturnal-shell
- **Original Noctalia**: https://github.com/noctalia-dev/noctalia-shell
- **Quickshell**: https://quickshell.org/
- **Noctalia v5 (C++ rewrite)**: https://noctalia.dev
