pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services

FocusScope {
    id: root

    property var clearConfirmDialog: null
    property var surfaceHost: null
    property var transientSurfaceTracker: null

    property string activeTab: "recents"
    property bool showKeyboardHints: false
    property int activeImageLoads: 0
    readonly property int maxConcurrentLoads: 3

    property string mode: "history"
    property string searchText: ClipboardService.searchText
    property string activeFilter: SettingsData.clipboardRememberTypeFilter ? SettingsData.clipboardTypeFilter : "all"

    readonly property bool clipboardAvailable: ClipboardService.clipboardAvailable
    readonly property bool pasteAvailable: ClipboardService.pasteAvailable
    readonly property int totalCount: ClipboardService.totalCount
    readonly property var clipboardEntries: ClipboardService.clipboardEntries
    readonly property var pinnedEntries: ClipboardService.pinnedEntries
    readonly property int pinnedCount: ClipboardService.pinnedCount
    readonly property var unpinnedEntries: ClipboardService.unpinnedEntries
    readonly property int selectedIndex: ClipboardService.selectedIndex
    readonly property bool keyboardNavigationActive: ClipboardService.keyboardNavigationActive

    readonly property var modalFocusScope: root
    property alias searchField: historyContent.searchField
    property alias editorView: editorView
    property alias keyboardController: keyboardController
    readonly property alias contextMenuActive: historyContent.contextMenuActive

    function closeContextMenu() {
        historyContent.closeContextMenu();
    }

    signal closeRequested
    signal instantCloseRequested

    onActiveTabChanged: {
        if (activeTab === "saved" && pinnedCount === 0) {
            activeTab = "recents";
            return;
        }
        ClipboardService.selectedIndex = 0;
        ClipboardService.keyboardNavigationActive = true;
    }
    onPinnedCountChanged: {
        if (activeTab === "saved" && pinnedCount === 0) {
            activeTab = "recents";
        }
    }
    onSearchTextChanged: ClipboardService.searchText = searchText

    onActiveFilterChanged: {
        ClipboardService.activeFilter = activeFilter;
        ClipboardService.selectedIndex = 0;
        ClipboardService.keyboardNavigationActive = true;
        ClipboardService.updateFilteredModel();
        if (SettingsData.clipboardRememberTypeFilter) {
            SettingsData.set("clipboardTypeFilter", activeFilter);
        }
    }

    function releaseTextInputFocus() {
        // Drop text-input focus before hiding the Wayland surface.
        if (searchField) {
            searchField.setFocus(false);
        }
        if (editorView) {
            editorView.releaseTextInputFocus();
        }
        root.forceActiveFocus();
    }

    function requestClose(instant) {
        releaseTextInputFocus();
        if (instant) {
            root.instantCloseRequested();
        } else {
            root.closeRequested();
        }
    }

    function hide() {
        requestClose(false);
    }

    function pasteSelected() {
        const entry = selectedEntry();
        if (!entry)
            return;
        ClipboardService.pasteEntry(entry, () => root.requestClose(true));
    }

    function pasteEntry(entry) {
        ClipboardService.pasteEntry(entry, () => root.requestClose(true));
    }

    function copyEntry(entry) {
        ClipboardService.copyEntry(entry, () => root.requestClose(false));
    }

    function selectedEntry() {
        const entries = activeTab === "saved" ? pinnedEntries : unpinnedEntries;
        if (!entries || entries.length === 0 || selectedIndex < 0 || selectedIndex >= entries.length)
            return null;
        return entries[selectedIndex];
    }

    function deleteEntry(entry) {
        ClipboardService.deleteEntry(entry);
    }

    function deletePinnedEntry(entry) {
        ClipboardService.deletePinnedEntry(entry, clearConfirmDialog);
    }

    function pinEntry(entry) {
        ClipboardService.pinEntry(entry);
    }

    function unpinEntry(entry) {
        ClipboardService.unpinEntry(entry);
    }

    function clearAll(entries) {
        ClipboardService.clearAll(entries);
    }

    function confirmClearAll() {
        const entries = activeTab === "saved" ? pinnedEntries : unpinnedEntries;
        if (!entries || entries.length === 0) {
            return;
        }

        const hasFilter = searchText.trim().length > 0 || activeFilter !== "all";
        let message;
        if (hasFilter) {
            message = activeTab === "saved" ? I18n.tr("This will permanently delete %1 filtered saved clipboard entries.").arg(entries.length) : I18n.tr("This will permanently delete %1 filtered recent clipboard entries.").arg(entries.length);
        } else if (activeTab === "saved") {
            message = I18n.tr("This will permanently delete all saved clipboard entries.");
        } else {
            const hasPinned = pinnedCount > 0;
            message = hasPinned ? I18n.tr("This will delete all unpinned entries. %1 pinned entries will be kept.").arg(pinnedCount) : I18n.tr("This will permanently delete all clipboard history.");
        }

        clearConfirmDialog.show(activeTab === "saved" ? I18n.tr("Clear Saved Items?") : I18n.tr("Clear History?"), message, function () {
            clearAll(entries);
            hide();
        }, function () {});
    }

    function getEntryPreview(entry) {
        return ClipboardService.getEntryPreview(entry);
    }

    function getEntryType(entry) {
        return ClipboardService.getEntryType(entry);
    }

    function updateFilteredModel() {
        ClipboardService.updateFilteredModel();
    }

    function refreshClipboard() {
        ClipboardService.refresh();
    }

    function editEntry(entry) {
        if (!entry || entry.isImage) {
            return;
        }
        editorView.setEntry(entry);
        mode = "editor";
    }

    function resetState() {
        activeImageLoads = 0;
        mode = "history";
        historyContent.closeContextMenu();
        historyContent.closeFilterMenu();
        activeFilter = SettingsData.clipboardRememberTypeFilter ? SettingsData.clipboardTypeFilter : "all";
        ClipboardService.reset();
        keyboardController.reset();
    }

    focus: true
    Keys.onPressed: function (event) {
        keyboardController.handleKey(event);
    }

    ClipboardKeyboardController {
        id: keyboardController
        modal: root
    }

    Item {
        id: historyView
        anchors.fill: parent
        opacity: 1
        scale: 1
        visible: opacity > 0.01
        enabled: root.mode === "history"

        ClipboardContent {
            id: historyContent
            anchors.fill: parent
            modal: root
            transientSurfaceTracker: root.transientSurfaceTracker
        }
    }

    ClipboardEditor {
        id: editorView
        anchors.fill: parent
        opacity: 0
        scale: 0.98
        visible: opacity > 0.01
        enabled: root.mode === "editor"
        focus: root.mode === "editor"
        modal: root
        keyController: keyboardController
    }

    states: [
        State {
            name: "history"
            when: root.mode === "history"
            PropertyChanges {
                target: historyView
                opacity: 1
                scale: 1
            }
            PropertyChanges {
                target: editorView
                opacity: 0
                scale: 0.98
            }
        },
        State {
            name: "editor"
            when: root.mode === "editor"
            PropertyChanges {
                target: historyView
                opacity: 0
                scale: 0.98
            }
            PropertyChanges {
                target: editorView
                opacity: 1
                scale: 1
            }
        }
    ]

    transitions: [
        Transition {
            from: "history"
            to: "editor"
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    duration: Theme.shortDuration
                    easing.type: Theme.standardEasing
                }
                NumberAnimation {
                    property: "scale"
                    duration: Theme.shortDuration
                    easing.type: Theme.emphasizedEasing
                }
            }
        },
        Transition {
            from: "editor"
            to: "history"
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    duration: Theme.shortDuration
                    easing.type: Theme.standardEasing
                }
                NumberAnimation {
                    property: "scale"
                    duration: Theme.shortDuration
                    easing.type: Theme.emphasizedEasing
                }
            }
        }
    ]
}
