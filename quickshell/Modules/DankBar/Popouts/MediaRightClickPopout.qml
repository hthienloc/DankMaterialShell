import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import qs.Common
import qs.Services
import qs.Widgets

DankPopout {
    id: root

    layerNamespace: "dms:media-right-click"

    property var triggerScreen: null

    popupWidth: 360
    popupHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0
    triggerWidth: 80
    screen: triggerScreen

    onBackgroundClicked: close()

    content: Component {
        Rectangle {
            id: popoutContent
            implicitHeight: mainColumn.implicitHeight + Theme.spacingL * 2
            color: "transparent"
            focus: true

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Escape) {
                    root.close();
                    event.accepted = true;
                }
            }

            Column {
                id: mainColumn
                width: parent.width - Theme.spacingL * 2
                anchors.centerIn: parent
                spacing: Theme.spacingM

                // Volume Section
                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: I18n.tr("Volume")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Rectangle {
                        width: parent.width
                        implicitHeight: volumeColumn.implicitHeight + Theme.spacingM * 2
                        color: Theme.nestedSurface
                        radius: Theme.cornerRadius

                        Column {
                            id: volumeColumn
                            width: parent.width - Theme.spacingM * 2
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            RowLayout {
                                width: parent.width
                                DankIcon {
                                    name: AudioService.sinkIcon(AudioService.sink)
                                    size: 20
                                    color: Theme.primary
                                }
                                Item { Layout.fillWidth: true }
                                StyledText {
                                    text: Math.round((AudioService.sink?.audio?.volume ?? 0) * 100) + "%"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceText
                                    opacity: 0.7
                                }
                            }

                            RowLayout {
                                width: parent.width
                                spacing: Theme.spacingM

                                DankIcon {
                                    name: AudioService.sink?.audio?.muted ? "volume_off" : "volume_up"
                                    size: 24
                                    color: muteIconMouseArea.containsMouse ? Theme.primary : Theme.surfaceText

                                    MouseArea {
                                        id: muteIconMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: AudioService.toggleMute()
                                    }
                                }

                                DankSlider {
                                    Layout.fillWidth: true
                                    value: Math.round((AudioService.sink?.audio?.volume ?? 0) * 100)
                                    maximum: AudioService.getMaxVolumePercent(AudioService.sink)
                                    onSliderValueChanged: val => {
                                        if (AudioService.sink?.audio)
                                            AudioService.sink.audio.volume = val / 100;
                                    }
                                }
                            }
                        }
                    }
                }

                // Media Players Section
                Column {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: MprisController.availablePlayers.length > 0

                    StyledText {
                        text: I18n.tr("Media Players") + " (" + MprisController.availablePlayers.length + ")"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Column {
                        id: playersColumn
                        width: parent.width
                        spacing: Theme.spacingS

                        Repeater {
                            model: MprisController.availablePlayers
                            delegate: Rectangle {
                                required property MprisPlayer modelData
                                width: parent.width
                                height: playerContent.implicitHeight + Theme.spacingM * 2
                                radius: Theme.cornerRadius
                                color: playerMouseArea.containsMouse ? Theme.primaryHoverLight : Theme.nestedSurface
                                border.color: modelData === MprisController.activePlayer ? Theme.primary : "transparent"
                                border.width: 1

                                MouseArea {
                                    id: playerMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MprisController.setActivePlayer(modelData)
                                }

                                RowLayout {
                                    id: playerContent
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.rightMargin: Theme.spacingM
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingM

                                    DankIcon {
                                        name: "music_note"
                                        size: 18
                                        color: modelData === MprisController.activePlayer ? Theme.primary : Theme.surfaceText
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        StyledText {
                                            text: modelData.identity || "Unknown Player"
                                            elide: Text.ElideRight
                                            width: parent.width
                                            color: Theme.surfaceText
                                            font.weight: modelData === MprisController.activePlayer ? Font.Medium : Font.Normal
                                        }
                                        StyledText {
                                            text: modelData.trackTitle || ""
                                            font.pixelSize: Theme.fontSizeSmall - 2
                                            color: Theme.surfaceText
                                            opacity: 0.7
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                            wrapMode: Text.WordWrap
                                            width: parent.width
                                            visible: text.length > 0
                                        }
                                    }

                                    DankIcon {
                                        name: modelData.isPlaying ? "pause" : "play_arrow"
                                        size: 16
                                        color: playIconMouseArea.containsMouse ? Theme.primary : Theme.surfaceText

                                        MouseArea {
                                            id: playIconMouseArea
                                            anchors.fill: parent
                                            anchors.margins: -Theme.spacingS
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                modelData.togglePlaying();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Output Devices Section
                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: I18n.tr("Output Devices") + " (" + AudioService.typedSinks.length + ")"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Column {
                        id: devicesColumn
                        width: parent.width
                        spacing: Theme.spacingS

                        Repeater {
                            model: AudioService.typedSinks
                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width
                                height: deviceContent.implicitHeight + Theme.spacingM * 2
                                radius: Theme.cornerRadius
                                color: deviceMouseArea.containsMouse ? Theme.primaryHoverLight : Theme.nestedSurface
                                border.color: modelData === AudioService.sink ? Theme.primary : "transparent"
                                border.width: 1

                                RowLayout {
                                    id: deviceContent
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.rightMargin: Theme.spacingM
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingM

                                    DankIcon {
                                        name: AudioService.sinkIcon(modelData)
                                        size: 18
                                        color: modelData === AudioService.sink ? Theme.primary : Theme.surfaceText
                                    }

                                    StyledText {
                                        text: AudioService.displayName(modelData)
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        color: Theme.surfaceText
                                        font.weight: modelData === AudioService.sink ? Font.Medium : Font.Normal
                                    }

                                    StyledText {
                                        text: Math.round((modelData.audio?.volume ?? 0) * 100) + "%"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        opacity: 0.7
                                        visible: modelData.audio !== null
                                        Layout.preferredWidth: 35
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    Item {
                                        width: 20
                                        height: 16
                                        DankIcon {
                                            name: "check"
                                            size: 16
                                            color: Theme.primary
                                            visible: modelData === AudioService.sink
                                            anchors.centerIn: parent
                                        }
                                    }
                                }

                                MouseArea {
                                    id: deviceMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: AudioService.setSink(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
