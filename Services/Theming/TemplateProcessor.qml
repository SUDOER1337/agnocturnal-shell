pragma Singleton
import QtQuick
import Quickshell
import qs.Commons

Singleton {
  id: root

  readonly property var schemeTypes: [
    {
      type: "light",
      key: "light",
      title: "Light",
      icon: ""
    },
    {
      type: "dark",
      key: "dark",
      title: "Dark",
      icon: ""
    }
  ]

  signal colorsGenerated

  function processWallpaperColors(wp, mode) {
  }
  function processPredefinedScheme(schemeData, mode, wallpaperPath) {
  }
  function isDiscordClientEnabled(name) {
    return false;
  }
  function isCodeClientEnabled(name) {
    return false;
  }
  function isTemplateEnabled(name) {
    return false;
  }
}
