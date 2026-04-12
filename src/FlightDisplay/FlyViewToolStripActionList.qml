/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQml.Models 2.12

import QGroundControl           1.0
import QGroundControl.Controls  1.0
import QtPositioning 5.15
ToolStripActionList {
    id: _root

    signal displayPreFlightChecklist

    model: [
        ToolStripAction {
            text:           qsTr("Plan")
            iconSource:     "/qmlimages/Plan.svg"
            onTriggered:    mainWindow.showPlanView()
        },
        ToolStripAction {
            property var _guidedController: globals.guidedControllerFlyView
            iconSource: "/res/qrcode.png"
          text:         qsTr("Marker")
          onTriggered:  {
                if(QGroundControl.settingsManager.appSettings.arUcoMarkerLat.value !==0 &&  QGroundControl.settingsManager.appSettings.arUcoMarkerLon.value !==0)
                {
                    setArUcoMarker()
                } else {
                    mainWindow.showMessageDialog("ArUcoMarker", "Marker lat long not set")
                }
          }
        },
        PreFlightCheckListShowAction { onTriggered: displayPreFlightChecklist() },
        GuidedActionTakeoff { },
        GuidedActionLand { },
        GuidedActionRTL { },
        GuidedActionPause { },
        GuidedActionActionList { }
    ]
}
