// File: Services/Theming/TemplateProcessor.qml
// =============================================================================
// Template processing and color generation pipeline.
// Bridges QML to the Python MD3 pipeline (template-processor.py) for
// wallpaper color extraction and predefined scheme expansion.
//
// Functions:
//   processWallpaperColors(wp, mode)          - Generate 48-colors from wallpaper
//   processPredefinedScheme(data, mode, wp)   - Expand predefined scheme to 48 colors
//   isDiscordClientEnabled(name)              - Stub: check Discord template
//   isCodeClientEnabled(name)                 - Stub: check code editor template
//   isTemplateEnabled(name)                   - Stub: check if a template is enabled
//
// Properties:
//   schemeTypes                               - 9 MD3 palette generation methods
//
// Signals:
//   colorsGenerated                           - Emitted after Python pipeline completes
// =============================================================================

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Theming

Singleton {
  id: root

  /** Palette generation method types matching template-processor.py --scheme-type.
  *  Each item has a `key` (used by generationMethod setting) and `name` (display text).
  *  Sources: https://github.com/material-foundation/material-color-utilities
  *  and template-processor.py in Scripts/python/src/theming/. */
  readonly property var schemeTypes: [
    {
      key: "tonal-spot",
      name: "Tonal Spot",
      icon: ""
    },
    {
      key: "content",
      name: "Content",
      icon: ""
    },
    {
      key: "fruit-salad",
      name: "Fruit Salad",
      icon: ""
    },
    {
      key: "rainbow",
      name: "Rainbow",
      icon: ""
    },
    {
      key: "monochrome",
      name: "Monochrome",
      icon: ""
    },
    {
      key: "vibrant",
      name: "Vibrant",
      icon: ""
    },
    {
      key: "faithful",
      name: "Faithful",
      icon: ""
    },
    {
      key: "dysfunctional",
      name: "Dysfunctional",
      icon: ""
    },
    {
      key: "muted",
      name: "Muted",
      icon: ""
    }
  ]

  signal colorsGenerated

  /** Flag set to true when the wallpaper pipeline ran and needs to
  *  post-process the expanded output into flat m* format for colors.json. */
  property bool postProcessColors: false

  // -- Color Generation Process --

  /** Subprocess that runs template-processor.py to extract colors from
  *  a wallpaper image or expand a predefined scheme to the full 48-color
  *  palette. On success, writes to template-expanded.json which is
  *  post-processed into colors.json (flat m* format) for Color.qml. */
  Process {
    id: genProcess
    running: false

    onExited: function (exitCode) {
      if (exitCode === 0) {
        Logger.d("TemplateProcessor", "Color generation completed");
        root.colorsGenerated();
      } else {
        Logger.e("TemplateProcessor", "Color generation failed with exit code", exitCode);
        Logger.w("TemplateProcessor", "stderr:", stderr.text.trim());
        return;
      }

      // Wallpaper pipeline: post-process expanded output into flat m* format
      if (root.postProcessColors) {
        root.postProcessColors = false;
        var expandedPath = Settings.configDir + "template-expanded.json";
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + expandedPath, false);
        xhr.send();
        if (xhr.status === 0 || xhr.status === 200) {
          try {
            var fullData = JSON.parse(xhr.responseText);
            var mode = Settings.data.colorSchemes.darkMode ? "dark" : "light";
            var variant = fullData[mode] || fullData.light || fullData.dark;
            if (variant) {
              ColorSchemeService.writeColorsToDisk(variant);
              Logger.d("TemplateProcessor", "Applied wallpaper colors to colors.json");
            }
          } catch (e) {
            Logger.e("TemplateProcessor", "Failed to post-process wallpaper colors:", e);
          }
        } else {
          Logger.e("TemplateProcessor", "Failed to read expanded palette from:", expandedPath);
        }
      }
    }

    stdout: StdioCollector {}
    stderr: StdioCollector {}
  }

  /** Generate app themes from a wallpaper image using the MD3 pipeline.
  *  Calls template-processor.py with the user's selected scheme type
  *  (tonal-spot, content, etc.) and dark/light mode.
  *  @param wp - Path to the wallpaper image (string)
  *  @param mode - "dark" or "light" */
  function processWallpaperColors(wp, mode) // Generate colors from wallpaper image
  {
    if (!wp) {
      Logger.e("TemplateProcessor", "processWallpaperColors: no wallpaper path");
      return;
    }

    // Validate generationMethod against known scheme types; fall back to tonal-spot
    var validKeys = root.schemeTypes.map(function (t) {
      return t.key;
    });
    var saved = Settings.data.colorSchemes.generationMethod;
    var method = validKeys.indexOf(saved) >= 0 ? saved : "tonal-spot";

    postProcessColors = true;
    var script = Quickshell.shellDir + "/Scripts/python/src/theming/template-processor.py";
    var outPath = Settings.configDir + "template-expanded.json";
    genProcess.command = ["python3", script, wp, "--scheme-type", method, "--" + mode, "-o", outPath];
    Logger.d("TemplateProcessor", "Generating colors from wallpaper:", wp, "->", outPath, "method:", method, "mode:", mode);
    genProcess.running = true;
  }

  /** Re-generate app templates from a predefined scheme.
  *  For predefined schemes the 30-token palette is already written by
  *  ColorSchemeService.writeColorsToDisk(). TemplateProcessor extends
  *  this to full 48-color output for external template rendering.
  *  @param schemeData - Full scheme JSON (may have dark/light variants)
  *  @param mode - "dark" or "light"
  *  @param wallpaperPath - Optional wallpaper path for template context */
  function processPredefinedScheme(schemeData, mode, wallpaperPath) // Generate templates from predefined scheme
  {
    if (!schemeData) {
      Logger.e("TemplateProcessor", "processPredefinedScheme: no scheme data");
      return;
    }
    // colors.json was already written by ColorSchemeService.writeColorsToDisk()
    // with all 30 flat tokens — use it as --scheme input.
    // Write expanded output to a separate file so colors.json (consumed by
    // Color.qml) stays in flat m* format.
    var script = Quickshell.shellDir + "/Scripts/python/src/theming/template-processor.py";
    var schemePath = Settings.configDir + "colors.json";
    var outPath = Settings.configDir + "template-expanded.json";

    genProcess.command = ["python3", script, "--scheme", schemePath, "--" + mode, "-o", outPath];
    Logger.d("TemplateProcessor", "Expanding predefined scheme via pipeline:", schemePath, "->", outPath, "mode:", mode);
    genProcess.running = true;
  }

  /** Stub: check if a Discord client template is enabled. */
  function isDiscordClientEnabled(name) // Stub: Discord template check
  {
    return false;
  }

  /** Stub: check if a code editor template is enabled. */
  function isCodeClientEnabled(name) // Stub: code editor template check
  {
    return false;
  }

  /** Stub: check if a named template is enabled. */
  function isTemplateEnabled(name) // Stub: template enabled check
  {
    return false;
  }
}
