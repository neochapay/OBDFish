/*
 * Copyright (C) 2016 Jens Drescher, Germany
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.obdfish 1.0
import "OBDDataObject.js" as OBDDataObject

Page
{
    allowedOrientations: Orientation.All
    id: id_page_dyn1
    property bool bPushDyn1Page: true
    property bool bInitPage: true
    property int iWaitForCommand: 0
    property int iCommandSequence: 1
    property string sParameter1: "Not supported"
    property string sParameter2: "Not supported"
    property string sParameter3: "Not supported"
    property string sParameter4: "Not supported"
    property string sParameter5: "Not supported"
    property string sParameter6: "Not supported"
    property variant arPIDPageArray : []
    property string sCycleTime : "0"
    property double iStartTime : 0
    property double iNowTime : 0

    onStatusChanged:
    {
        if (status === PageStatus.Active && bPushDyn1Page)
        {
            bPushDyn1Page = false;

            //pageStack.pushAttached(Qt.resolvedUrl("Dyn4Page.qml"));
        }

        if (status === PageStatus.Active)
        {
            bInitPage = true;

            iCommandSequence = 1;
            sCycleTime = 0;
            iStartTime = 0;
            iNowTime = 0;

            //Fill PID's for this Page into an array. Empty spaces between two PID's should be avoided.
            var arPIDsPage = arPIDsPagesArray[2].split(",");
            var arPIDPageArrayTemp = [];
            for (var i = 0; i < arPIDsPage.length; i++)
            {
                if (arPIDsPage[i] !== "0000")
                    arPIDPageArrayTemp.push(arPIDsPage[i]);
            }
            arPIDPageArray = arPIDPageArrayTemp;

            id_PlotWidget.reset();

            bInitPage = false;
        }
    }

    Timer
    {
        //This timer is called cyclically to query ELM
        id: timQueryELMParameters
        interval: 55
        running: ((status === PageStatus.Active) && !bInitPage)
        repeat: true
        onTriggered:
        {
            //Check if ELM has answered correctly to current AT command
            if (bCommandRunning == false)
            {
                iWaitForCommand = 0;

                //console.log("timQueryELMParameters step: " + iCommandSequence.toString());

                //Send first command: query engine temperature
                switch (iCommandSequence)
                {
                    case 1:
                        //If a start time was saved before, calculate cycle time.
                        if (iStartTime !== 0)
                        {
                            iNowTime = new Date().getTime();

                            sCycleTime = (iNowTime - iStartTime).toString();
                        }

                        //Save current time in order to calculate the cycle time.
                        iStartTime = new Date().getTime();

                        if (arPIDPageArray.length > 0 && fncStartCommand(arPIDPageArray[0] + "1"))
                            iCommandSequence++;
                        else
                        {
                            sCoverValue1 = "";
                            iCommandSequence = iCommandSequence + 2;
                        }
                        break;
                    case 2:
                        var sValue = OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, arPIDPageArray[0].toUpperCase());
                        sCoverValue1 = sValue + OBDDataObject.arrayLookupPID[arPIDPageArray[0]].unittext;
                        sParameter1 = OBDDataObject.arrayLookupPID[arPIDPageArray[0]].labeltext + ": " + sCoverValue1;

                        if (arPIDPageArray.length == 1)
                        {
                            id_PlotWidget.addValue(sValue);
                            id_PlotWidget.update();
                        }

                        iCommandSequence++;
                        break;
                    case 3:
                        if (arPIDPageArray.length > 1 && fncStartCommand(arPIDPageArray[1] + "1"))
                            iCommandSequence++;
                        else
                        {
                            sCoverValue2 = "";
                            iCommandSequence = iCommandSequence + 2;
                        }
                        break;
                    case 4:
                        sCoverValue2 = OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, arPIDPageArray[1].toUpperCase()) +
                                       OBDDataObject.arrayLookupPID[arPIDPageArray[1]].unittext;
                        sParameter2 = OBDDataObject.arrayLookupPID[arPIDPageArray[1]].labeltext + ": " + sCoverValue2;
                        iCommandSequence++;
                        break;
                    case 5:
                        if (arPIDPageArray.length > 2 && fncStartCommand(arPIDPageArray[2] + "1"))
                            iCommandSequence++;
                        else
                        {
                            sCoverValue3 = "";
                            iCommandSequence = iCommandSequence + 2;
                        }
                        break;
                    case 6:
                        sCoverValue3 = OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, arPIDPageArray[2].toUpperCase()) +
                                       OBDDataObject.arrayLookupPID[arPIDPageArray[2]].unittext;
                        sParameter3 = OBDDataObject.arrayLookupPID[arPIDPageArray[2]].labeltext + ": " + sCoverValue3;
                        iCommandSequence++;
                        break;
                    case 7:
                        if (arPIDPageArray.length > 3 && fncStartCommand(arPIDPageArray[3] + "1"))
                            iCommandSequence++;
                        else
                            iCommandSequence = iCommandSequence + 2;
                        break;
                    case 8:
                        sParameter4 = OBDDataObject.arrayLookupPID[arPIDPageArray[3]].labeltext + ": " +
                                OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, arPIDPageArray[3].toUpperCase()) +
                                OBDDataObject.arrayLookupPID[arPIDPageArray[3]].unittext;
                        iCommandSequence++;
                        break;
                    case 9:
                        if (arPIDPageArray.length > 4 && fncStartCommand(arPIDPageArray[4] + "1"))
                            iCommandSequence++;
                        else
                            iCommandSequence = iCommandSequence + 2;
                        break;
                    case 10:
                        sParameter5 = OBDDataObject.arrayLookupPID[arPIDPageArray[4]].labeltext + ": " +
                                OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, arPIDPageArray[4].toUpperCase()) +
                                OBDDataObject.arrayLookupPID[arPIDPageArray[4]].unittext;
                        iCommandSequence++;
                        break;
                    case 11:
                        if (arPIDPageArray.length > 5 && fncStartCommand(arPIDPageArray[5] + "1"))
                            iCommandSequence++;
                        else
                            iCommandSequence = 1;
                        break;
                    case 12:
                        sParameter6 = OBDDataObject.arrayLookupPID[arPIDPageArray[5]].labeltext + ": " +
                                OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, arPIDPageArray[5].toUpperCase()) +
                                OBDDataObject.arrayLookupPID[arPIDPageArray[5]].unittext;

                            iCommandSequence = 1;
                        break;
                }
            }
            else
            {
                //ELM has not yet answered. Or the answer is not complete.
                //Check if wait time is over.
                if (iWaitForCommand == 20)
                {
                    //Skip now.
                    bCommandRunning = false;
                }
                else
                    iWaitForCommand++;
            }
        }
    }

    SilicaFlickable
    {
        anchors.fill: parent
        contentHeight: id_Column_FirstCol.height + Theme.paddingLarge;

        VerticalScrollDecorator {}

        PullDownMenu
        {
            MenuItem
            {
                text: qsTr("Settings")
                onClicked: {pageStack.push(Qt.resolvedUrl("SettingsPage.qml"), {iPIDPageIndex: 2})}
            }
        }
        Column
        {
            id: id_Column_FirstCol

            spacing: Theme.paddingLarge
            width: parent.width

            PageHeader { title: qsTr("Dynamic Values 3") }

            Row
            {
                IconButton
                {
                    icon.source: "image://theme/icon-m-question"
                    onClicked:
                    {
                        fncShowMessage(1,qsTr("The more parameters are requested, the higher the cycle time.<br>To get a more responsive cycle time, go to settings and reduce amount of parameters for this page."), 20000);
                    }
                }
                Label
                {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeMedium
                    text: qsTr("Cycle time: ") + sCycleTime + "ms";
                }
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            Label
            {
                visible: (arPIDPageArray.length > 0)
                text: sParameter1;
            }
            Separator
            {
                visible: (arPIDPageArray.length > 0)
                color: Theme.highlightColor
                width: parent.width
            }
            Label
            {
                visible: (arPIDPageArray.length > 1)
                text: sParameter2;
            }
            Separator
            {
                visible: (arPIDPageArray.length > 1)
                color: Theme.highlightColor
                width: parent.width
            }
            Label
            {
                visible: (arPIDPageArray.length > 2)
                text: sParameter3;
            }
            Separator
            {
                visible: (arPIDPageArray.length > 2)
                color: Theme.highlightColor
                width: parent.width
            }
            Label
            {
                visible: (arPIDPageArray.length > 3)
                text: sParameter4;
            }
            Separator
            {
                visible: (arPIDPageArray.length > 3)
                color: Theme.highlightColor
                width: parent.width
            }
            Label
            {
                visible: (arPIDPageArray.length > 4)
                text: sParameter5;
            }
            Separator
            {
                visible: (arPIDPageArray.length > 4)
                color: Theme.highlightColor
                width: parent.width
            }
            Label
            {
                visible: (arPIDPageArray.length > 5)
                text: sParameter6;
            }
            PlotWidget
            {
                id: id_PlotWidget
                visible: (arPIDPageArray.length == 1)
                width: parent.width
                height: 150
                plotColor: Theme.highlightColor
                scaleColor: Theme.secondaryHighlightColor
            }
        }
    }
}
