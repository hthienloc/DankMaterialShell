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

    popupWidth: 320
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

                    RowLayout {
                        width: parent.width
                        DankIcon {
                            name: AudioService.sinkIcon(AudioService.sink)
                            size: 20
                            color: Theme.primary
                        }
                        StyledText {
                            text: I18n.tr("Volume")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            Layout.fillWidth: true
                        }
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

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.onSurface
                    opacity: 0.1
                }

                // Media Players Section
                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: I18n.tr("Media Players") + " (" + MprisController.availablePlayers.length + ")"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                        color: Theme.primary
                        opacity: 0.8
                    }

                    Repeater {
                        model: MprisController.availablePlayers
                        delegate: Rectangle {
                            required property MprisPlayer modelData
                            width: parent.width
                            height: 64
                            radius: Theme.cornerRadius
                            color: playerMouseArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.1) : "transparent"
                            border.color: modelData === MprisController.activePlayer ? Theme.primary : "transparent"
                            border.width: 1

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
                                        width: parent.width
                                        visible: text.length > 0
                                    }
                                }

                                DankIcon {
                                    name: modelData.isPlaying ? "pause" : "play_arrow"
                                    size: 16
                                    color: Theme.surfaceText
                                }
                            }

                            MouseArea {
                                id: playerMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: MprisController.setActivePlayer(modelData)
                            }
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.onSurface
                    opacity: 0.1
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
                        opacity: 0.8
                    }

                    Repeater {
                        model: AudioService.typedSinks
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width
                            height: 64
                            radius: Theme.cornerRadius
                            color: deviceMouseArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.1) : "transparent"
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

                                DankIcon {
                                    name: "check"
                                    size: 16
                                    color: Theme.primary
                                    visible: modelData === AudioService.sink
                                }
                            }

                            MouseArea {
                                id: deviceMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: AudioService.setSink(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
