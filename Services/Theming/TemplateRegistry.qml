// File: Services/Theming/TemplateRegistry.qml
// =============================================================================
// Registry of known application templates for theming.
// Currently a stub — template discovery and registration is pending implementation.
//
// Functions:
//   resolvedCodeClientPaths(name) - Stub: resolve paths for a code editor
//   writeUserTemplatesToml()       - Stub: write user template configuration
//
// Properties:
//   terminals       - List of known terminal emulator templates
//   applications    - List of known application templates
//   discordClients  - List of known Discord client templates
//   codeClients     - List of known code editor templates
//   emacsClients    - List of known Emacs client templates
// =============================================================================

pragma Singleton
import QtQuick
import Quickshell

Singleton {
  id: root

  // FIXME: All template lists are empty — template registration not yet implemented.
  // These should be populated from settings or auto-discovered at runtime.
  readonly property var terminals: []
  readonly property var applications: []
  readonly property var discordClients: []
  readonly property var codeClients: []
  readonly property var emacsClients: []

  /** Stub: resolve file paths for a named code editor client. */
  function resolvedCodeClientPaths(name) // Stub: resolve code editor paths
  {
    return [];
  }

  /** Stub: write user template configuration to disk. */
  function writeUserTemplatesToml() // Stub: write template config
  {
    // TODO: Implement user template persistence
  }
}
