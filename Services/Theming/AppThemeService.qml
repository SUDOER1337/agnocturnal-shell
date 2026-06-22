// File: Services/Theming/AppThemeService.qml
// =============================================================================
// Application theme generation service.
// Coordinates between color scheme selection (wallpaper-derived or predefined)
// and template generation (GTK themes, terminal themes, etc.).
// Reacts to dark mode, wallpaper, and scheme changes automatically.
//
// Functions:
//   init()                       - Initialize the service
//   generate()                   - Generate themes based on current settings
//   generateFromWallpaper()      - Generate themes from wallpaper-derived colors
//   generateFromPredefinedScheme() - Generate themes from a predefined scheme
//
// Connections:
//   WallpaperService.onWallpaperChanged - Triggers theme regeneration on wallpaper change
//   Settings.data.colorSchemes.*       - Reacts to dark mode, monitor, method changes
// =============================================================================

pragma Singleton

import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI

Singleton {
  id: root

  // === Wallpaper Change Handler ===

  /** When the wallpaper changes, regenerate app themes.
  *  If useWallpaperColors is on, generates from the new wallpaper.
  *  If a predefined scheme is active, regenerates templates from cached scheme data
  *  (without re-writing colors.json).
  *  Falls back to re-applying the stored predefined scheme. */
  Connections {
    target: WallpaperService

    function onWallpaperChanged(screenName, path) {
      var effectiveMonitor = Settings.data.colorSchemes.monitorForColors;
      if (effectiveMonitor === "" || effectiveMonitor === undefined) {
        effectiveMonitor = Screen.name;
      }

      if (screenName !== effectiveMonitor)
        return;

      if (Settings.data.colorSchemes.useWallpaperColors) {
        generateFromWallpaper();
      } else if (ColorSchemeService.lastPredefinedSchemeData) {
        // Regenerate templates only; skip applyScheme so colors.json stays untouched
        // (TemplateProcessor skips identical writes internally).
        generateFromPredefinedScheme(ColorSchemeService.lastPredefinedSchemeData);
      } else {
        ColorSchemeService.applyScheme(Settings.data.colorSchemes.predefinedScheme);
      }
    }
  }

  // === Settings Change Handlers ===

  Connections {
    target: Settings.data.colorSchemes
    function onDarkModeChanged() {
      Logger.d("AppThemeService", "Detected dark mode change");
      generate();
    }
    function onMonitorForColorsChanged() {
      if (Settings.data.colorSchemes.useWallpaperColors) {
        Logger.d("AppThemeService", "Monitor for colors changed to:", Settings.data.colorSchemes.monitorForColors);
        generateFromWallpaper();
      }
    }
    function onGenerationMethodChanged() {
      Logger.d("AppThemeService", "Generation method changed to:", Settings.data.colorSchemes.generationMethod);
      generate();
    }
  }

  // === Public API ===

  /** Initialize the AppThemeService.
  *  Starts listening for changes and ensures the singleton is instantiated. */
  function init() // Start the theme service
  {
    Logger.i("AppThemeService", "Service started");
  }

  /** Generate (or regenerate) app themes based on the current settings.
  *  Delegates to wallpaper pipeline or predefined scheme pipeline. */
  function generate() // Regenerate app themes
  {
    if (Settings.data.colorSchemes.useWallpaperColors) {
      generateFromWallpaper();
    } else {
      // applyScheme triggers template generation via schemeReader.onLoaded callback
      ColorSchemeService.applyScheme(Settings.data.colorSchemes.predefinedScheme);
    }
  }

  /** Generate app themes from wallpaper-derived colors.
  *  Resolves the effective monitor and delegates to TemplateProcessor. */
  function generateFromWallpaper() // Generate from wallpaper colors
  {
    var effectiveMonitor = Settings.data.colorSchemes.monitorForColors;
    if (effectiveMonitor === "" || effectiveMonitor === undefined) {
      effectiveMonitor = Screen.name;
    }

    const wp = WallpaperService.getWallpaper(effectiveMonitor);
    if (!wp) {
      Logger.e("AppThemeService", "No wallpaper found for monitor:", effectiveMonitor);
      return;
    }
    const mode = Settings.data.colorSchemes.darkMode ? "dark" : "light";
    TemplateProcessor.processWallpaperColors(wp, mode);
  }

  /** Generate app themes from a predefined color scheme data.
  *  @param schemeData - Full scheme JSON object (with optional dark/light variants) */
  function generateFromPredefinedScheme(schemeData) // Generate from predefined scheme
  {
    Logger.i("AppThemeService", "Generating templates from predefined color scheme");
    const mode = Settings.data.colorSchemes.darkMode ? "dark" : "light";
    var effectiveMonitor = Settings.data.colorSchemes.monitorForColors;
    if (effectiveMonitor === "" || effectiveMonitor === undefined) {
      effectiveMonitor = Screen.name;
    }
    const wallpaperPath = WallpaperService.getWallpaper(effectiveMonitor) || "";
    TemplateProcessor.processPredefinedScheme(schemeData, mode, wallpaperPath);
  }
}
