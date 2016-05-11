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
import "OBDDataObject.js" as OBDDataObject

Page
{
    allowedOrientations: Orientation.All
    id: id_page_secondpage
    property bool bPushDyn2Page: true
    property int iWaitForCommand: 0
    property int iCommandQuery: 0    
    property string sIntakePressure: "Not supported"
    property string sIntakeTemp: "Not supported"
    property string sAirFlowRate: "Not supported"

    onStatusChanged:
    {
        if (status === PageStatus.Active && bPushDyn2Page)
        {
            bPushDyn2Page = false;
            //pageStack.pushAttached(Qt.resolvedUrl("GeneralInfo.qml"));
        }
    }

    Timer
    {
        //This timer is called cyclically to query ELM
        id: timQueryELMParameters
        interval: 55
        running: (status === PageStatus.Active)
        repeat: true
        onTriggered:
        {
            var sReadValue = "";

            //Check if ELM has answered correctly to current AT command
            if (bCommandRunning == false)
            {
                iWaitForCommand = 0;

                //Send first command: query engine temperature
                //Hier muss noch abgefragt werden, ob diese PID überhaupt unterstützt wird. TODO
                if (iCommandQuery == 0)
                {
                    iCommandQuery = 1;
                    fncStartCommand("010B1");
                }
                else if (iCommandQuery == 1)
                {
                    //Evaluate answer from ELM
                    sReadValue = OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "010B");
                    if (sReadValue !== null)
                        sIntakePressure = sReadValue;

                    //Send next command
                    iCommandQuery = 2;
                    fncStartCommand("010F1");
                }
                else if (iCommandQuery == 2)
                {
                    //Evaluate answer from ELM
                    sReadValue = OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "010F");
                    if (sReadValue !== null)
                        sIntakeTemp = sReadValue;

                    //Send next command
                    iCommandQuery = 3;
                    fncStartCommand("01101");
                }
                else if (iCommandQuery == 3)
                {
                    //Evaluate answer from ELM
                    sReadValue = OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "0110");
                    if (sReadValue !== null)
                        sAirFlowRate = sReadValue;

                    //Send next command
                    iCommandQuery = 1;
                    fncStartCommand("010B1");
                }              
            }
            else
            {
                //ELM has not yet answered. Or the answer is not complete.
                //Check if wait time is over.
                if (iWaitForCommand == 10)
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

        Column
        {
            id: id_Column_FirstCol

            spacing: Theme.paddingSmall
            width: parent.width

            PageHeader { title: qsTr("Dynamic Values 2") }

            Label
            {
                text: "Intake Air Pressure: " + sIntakePressure + "kPa";
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            Label
            {
                text: "Intake Air Temp: " + sIntakeTemp + "C°";
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            Label
            {
                text: "Air Flow Rate: " + sAirFlowRate + "grams/sec";
            }

        }
    }
}
