import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.Agnocturnal
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  // List of plugin sources
  ColumnLayout {
    spacing: Style.marginM
    Layout.fillWidth: true

    Repeater {
      id: pluginSourcesRepeater
      model: PluginRegistry.pluginSources || []

      delegate: NBox {
        Layout.fillWidth: true
        implicitHeight: sourceRow.implicitHeight + Style.margin2L
        color: Color.mSurface

        RowLayout {
          id: sourceRow
          anchors.fill: parent
          anchors.margins: Style.marginL
          spacing: Style.marginM

          NIcon {
            icon: "brand-github"
            pointSize: Style.fontSizeL
          }

          ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            NText {
              text: modelData.name
              color: Color.mOnSurface
              Layout.fillWidth: true
            }

            NText {
              text: modelData.url
              font.pointSize: Style.fontSizeXS
              color: Color.mOnSurfaceVariant
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
          }

          NIconButton {
            icon: "trash"
            tooltipText: "Remove plugin source"
            visible: index !== 0 // Cannot remove official source
            baseSize: Style.baseWidgetSize * 0.7
            onClicked: {
              PluginRegistry.removePluginSource(modelData.url);
            }
          }

          // Enable/Disable a source
          NToggle {
            checked: modelData.enabled !== false // Default to true if not set
            baseSize: Style.baseWidgetSize * 0.7
            onToggled: checked => {
                         PluginRegistry.setSourceEnabled(modelData.url, checked);
                         PluginService.refreshAvailablePlugins();
                         ToastService.showNotice("Plugins", "Refreshing plugins list...");
                       }
          }
        }
      }
    }
  }

  // Add custom repository
  NButton {
    text: "Add custom repository"
    icon: "plus"
    onClicked: {
      addSourceDialog.open();
    }
    Layout.fillWidth: true
  }

  // Add source dialog
  Popup {
    id: addSourceDialog
    parent: Overlay.overlay
    modal: true
    dim: false
    anchors.centerIn: parent
    width: 500
    padding: Style.marginL

    background: Rectangle {
      color: Color.mSurface
      radius: Style.radiusS
      border.color: Color.mPrimary
      border.width: Style.borderM
    }

    contentItem: ColumnLayout {
      width: parent.width
      spacing: Style.marginL

      NHeader {
        label: "Add plugin source"
        description: "Add a GitHub repository as a plugin source."
      }

      NTextInput {
        id: sourceNameInput
        label: "Repository name"
        placeholderText: "My Custom Plugins"
        Layout.fillWidth: true
      }

      NTextInput {
        id: sourceUrlInput
        label: "Repository URL"
        placeholderText: "https://github.com/user/repo"
        Layout.fillWidth: true
      }

      RowLayout {
        spacing: Style.marginM
        Layout.fillWidth: true

        Item {
          Layout.fillWidth: true
        }

        NButton {
          text: "Cancel"
          onClicked: addSourceDialog.close()
        }

        NButton {
          text: "Add"
          backgroundColor: Color.mPrimary
          textColor: Color.mOnPrimary
          enabled: sourceNameInput.text.length > 0 && sourceUrlInput.text.length > 0
          onClicked: {
            if (PluginRegistry.addPluginSource(sourceNameInput.text, sourceUrlInput.text)) {
              ToastService.showNotice("Plugins", "Plugin source added successfully");
              PluginService.refreshAvailablePlugins();
              addSourceDialog.close();
              sourceNameInput.text = "";
              sourceUrlInput.text = "";
            } else {
              ToastService.showError("Plugins", "Failed to add plugin source");
            }
          }
        }
      }
    }
  }

  // Listen to plugin registry changes
  Connections {
    target: PluginRegistry

    function onPluginsChanged() {
      // Force model refresh for plugin sources
      pluginSourcesRepeater.model = undefined;
      Qt.callLater(function () {
        pluginSourcesRepeater.model = Qt.binding(function () {
          return PluginRegistry.pluginSources || [];
        });
      });
    }
  }
}
