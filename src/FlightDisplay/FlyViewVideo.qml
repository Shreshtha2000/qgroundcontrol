/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick 2.12

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Controllers   1.0
import QGroundControl.ScreenTools   1.0

Item {
    id:         _root
    visible:    QGroundControl.videoManager.hasVideo

    property Item pipState: videoPipState
    QGCPipState {
        id:         videoPipState
        pipOverlay: _pipOverlay
        isDark:     true

        onWindowAboutToOpen: {
            QGroundControl.videoManager.stopVideo()
            videoStartDelay.start()
        }

        onWindowAboutToClose: {
            QGroundControl.videoManager.stopVideo()
            videoStartDelay.start()
        }

        onStateChanged: {
            if (pipState.state !== pipState.fullState) {
                QGroundControl.videoManager.fullScreen = false
            }
        }
    }
    Rectangle {
        id: clickRect
        anchors.fill: parent
        color: "transparent"
        z:100
        property var p1: null
        property var p2: null
        property bool setFirst: true
        property double sensorWidth: 8.2 //mm
        property double fov: 90
        property double focal_length: sensorWidth / (2*Math.tan((fov*Math.PI/180)/2))
        property double gsdK: _activeVehicle!=null? (_activeVehicle.altitudeRelative.value*sensorWidth)/(focal_length*720): 0
        MouseArea {
            anchors.fill: parent
            enabled: _activeVehicle != null
            onClicked: {
                if (clickRect.setFirst) {
                    clickRect.p1 = {x: mouse.x, y: mouse.y}
                    clickRect.p2 = null   // reset second point
                } else {
                    clickRect.p2 = {x: mouse.x, y: mouse.y}
                }
                clickRect.setFirst = !clickRect.setFirst
                console.log("clicked")
            }
        }

        Rectangle {
            visible: clickRect.p1 !== null
            x: clickRect.p1 ? clickRect.p1.x - 5 : 0
            y: clickRect.p1 ? clickRect.p1.y - 5 : 0
            width: 10
            height: 10
            radius: 5
            color: "red"
        }

        Rectangle {
            visible: clickRect.p2 !== null
            x: clickRect.p2 ? clickRect.p2.x - 5 : 0
            y: clickRect.p2 ? clickRect.p2.y - 5 : 0
            width: 10
            height: 10
            radius: 5
            color: "green"
        }

        Canvas {
            anchors.fill: parent
            id: distanceLine
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                if (clickRect.p1 && clickRect.p2) {
                    ctx.beginPath()
                    ctx.moveTo(clickRect.p1.x, clickRect.p1.y)
                    ctx.lineTo(clickRect.p2.x, clickRect.p2.y)
                    ctx.lineWidth = 2
                    ctx.strokeStyle = "yellow"
                    ctx.stroke()
                }
            }

            Connections {
                target: clickRect
                function onP1Changed() { distanceLine.requestPaint() }
                function onP2Changed() { distanceLine.requestPaint() }
            }
        }

        Text {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"
            font.pixelSize: 18

            text: {
                if (clickRect.p1 && clickRect.p2) {
                    var dx = clickRect.p2.x - clickRect.p1.x
                    var dy = clickRect.p2.y - clickRect.p1.y
                    var dist = Math.sqrt(dx*dx + dy*dy)
                    var dist_m = clickRect.gsdK * dist
                    return "Distance: " + dist_m.toFixed(2) + " m"
                }
                return "Click 2 points"
            }
        }
    }
    Timer {
        id:           videoStartDelay
        interval:     2000;
        running:      false
        repeat:       false
        onTriggered:  QGroundControl.videoManager.startVideo()
    }

    //-- Video Streaming
    FlightDisplayViewVideo {
        id:             videoStreaming
        anchors.fill:   parent
        useSmallFont:   _root.pipState.state !== _root.pipState.fullState
        visible:        QGroundControl.videoManager.isGStreamer
    }
    //-- UVC Video (USB Camera or Video Device)
    Loader {
        id:             cameraLoader
        anchors.fill:   parent
        visible:        !QGroundControl.videoManager.isGStreamer
        source:         QGroundControl.videoManager.uvcEnabled ? "qrc:/qml/FlightDisplayViewUVC.qml" : "qrc:/qml/FlightDisplayViewDummy.qml"
    }

    QGCLabel {
        text: qsTr("Double-click to exit full screen")
        font.pointSize: ScreenTools.largeFontPointSize
        visible: QGroundControl.videoManager.fullScreen && flyViewVideoMouseArea.containsMouse
        anchors.centerIn: parent
    }

    MouseArea {
        id: flyViewVideoMouseArea
        anchors.fill:       parent
        enabled:            pipState.state === pipState.fullState
        hoverEnabled: true
        onDoubleClicked:    QGroundControl.videoManager.fullScreen = !QGroundControl.videoManager.fullScreen
    }

    ProximityRadarVideoView{
        anchors.fill:   parent
        vehicle:        QGroundControl.multiVehicleManager.activeVehicle
    }

    ObstacleDistanceOverlayVideo {
        id: obstacleDistance
        showText: pipState.state === pipState.fullState
    }
}
