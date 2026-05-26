import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Panels.Settings
import qs.Services.UI
import qs.Widgets

Rectangle {
  id: root

  property ShellScreen screen
  property int requestedTab: 0
  property var requestedEntry: null
  property int _pendingSubTab: -1
  property string searchText: ""
  property var _settingsContent: null

  signal closeRequested

  color: "transparent"

  // Delegate functions to SettingsContent
  function initialize() {
    if (_settingsContent) {
      if (root.requestedEntry) {
        _settingsContent.requestedEntry = root.requestedEntry;
        _settingsContent.initialize();
        const entry = root.requestedEntry;
        root.requestedEntry = null;
        Qt.callLater(() => _settingsContent.navigateToResult(entry));
      } else {
        _settingsContent.requestedTab = root.requestedTab;
        if (_pendingSubTab >= 0) {
          _settingsContent._pendingSubTab = _pendingSubTab;
          _pendingSubTab = -1;
        }
        _settingsContent.initialize();
      }
    }
  }

  function scrollDown() { if (_settingsContent) _settingsContent.scrollDown(); }
  function scrollUp() { if (_settingsContent) _settingsContent.scrollUp(); }
  function scrollPageDown() { if (_settingsContent) _settingsContent.scrollPageDown(); }
  function scrollPageUp() { if (_settingsContent) _settingsContent.scrollPageUp(); }
  function selectNextTab() { if (_settingsContent) _settingsContent.selectNextTab(); }
  function selectPreviousTab() { if (_settingsContent) _settingsContent.selectPreviousTab(); }

  // Embed SettingsContent - starts with collapsed sidebar to fit CC width
  Loader {
    anchors.fill: parent
    active: true

    sourceComponent: SettingsContent {
      screen: root.screen
      sidebarExpanded: false // Start collapsed for CC width

      onCloseRequested: root.closeRequested()

      Component.onCompleted: {
        root._settingsContent = this;
      }
    }
  }
}
