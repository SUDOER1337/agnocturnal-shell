pragma Singleton
import QtQuick
import Quickshell

Singleton {
  id: root

  readonly property var terminals: []
  readonly property var applications: []
  readonly property var discordClients: []
  readonly property var codeClients: []
  readonly property var emacsClients: []

  function resolvedCodeClientPaths(name) { return []; }
  function writeUserTemplatesToml() {}
}
