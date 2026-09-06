import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.Widgets

DankOSD {
    id: root

    property string workspaceLabel: ""
    property var lastActiveWorkspaceId: null

    readonly property real horizontalPadding: Theme.spacingL
    readonly property real itemSpacing: Theme.spacingM
    readonly property real textWidth: Math.ceil(textMetrics.width)

    osdWidth: Math.min(
        Math.max(140, horizontalPadding * 2 + Theme.iconSize + itemSpacing + textWidth),
        screenWidth - Theme.spacingM * 2
    )
    osdHeight: 48
    autoHideInterval: 1500
    enableMouseInteraction: false

    function initActiveWorkspace() {
        if (root.lastActiveWorkspaceId !== null)
            return;
        const screenName = root.screen?.name;
        const active = NiriService.allWorkspaces.find(ws => (!screenName || ws.output === screenName) && ws.is_active);
        if (active) {
            root.lastActiveWorkspaceId = active.id;
        }
    }

    function updateWorkspaceInfo(ws) {
        if (!ws)
            return;
        const num = (ws.idx !== undefined && ws.idx !== null && ws.idx > 0) ? ws.idx : (typeof ws.id === "number" ? ws.id : null);
        const name = (ws.name ?? "").trim();

        if (num !== null) {
            if (name !== "" && name !== String(num)) {
                root.workspaceLabel = I18n.tr("Workspace %1: %2", "workspace switch OSD, %1 is workspace number, %2 is workspace name").arg(num).arg(name);
            } else {
                root.workspaceLabel = I18n.tr("Workspace %1", "workspace switch OSD, %1 is workspace number").arg(num);
            }
        } else if (name !== "") {
            root.workspaceLabel = name;
        } else {
            root.workspaceLabel = I18n.tr("Workspace", "fallback label when workspace has no number or name");
        }
    }

    Component.onCompleted: {
        root.initActiveWorkspace();
    }

    Connections {
        target: NiriService

        function onAllWorkspacesChanged() {
            root.initActiveWorkspace();
        }

        function onWorkspaceActivated(workspace, focused) {
            if (!SettingsData.osdWorkspaceEnabled)
                return;
            if (!workspace || !workspace.id)
                return;

            const screenName = root.screen?.name;
            if (screenName && workspace.output && screenName !== workspace.output)
                return;

            const previousId = root.lastActiveWorkspaceId;
            root.lastActiveWorkspaceId = workspace.id;

            if (previousId === null || previousId === workspace.id)
                return;
            if (NiriService.inOverview)
                return;

            root.updateWorkspaceInfo(workspace);
            root.show();
        }
    }

    TextMetrics {
        id: textMetrics
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        font.family: Theme.fontFamily
        text: root.workspaceLabel
    }

    content: Item {
        anchors.fill: parent

        RowLayout {
            anchors {
                fill: parent
                leftMargin: root.horizontalPadding
                rightMargin: root.horizontalPadding
            }
            spacing: root.itemSpacing

            DankIcon {
                Layout.alignment: Qt.AlignVCenter
                name: "view_module"
                size: Theme.iconSize
                color: Theme.primary
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: root.workspaceLabel
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                elide: Text.ElideRight
            }
        }
    }
}
