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
import "OBDComm2.js" as OBDComm2
import "OBDDataObject.js" as OBDDataObject

Page
{
    allowedOrientations: Orientation.All
    id: id_page_secondpage
    property bool bPushSecondPage: true
    property int iWaitForCommand: 0
    property int iCommandQuery: 0

    onStatusChanged:
    {
        if (status === PageStatus.Active && bPushSecondPage)
        {
            bPushSecondPage = false;
            //pageStack.pushAttached(Qt.resolvedUrl("NumbersPage.qml"));
        }
    }

    Timer
    {
        //This timer is called cyclically to query ELM
        id: timQueryELMParameters
        interval: 1000
        running: (status === PageStatus.Active)
        repeat: true
        onTriggered:
        {
            console.log("Timer second page");

            //Check if ELM has answered correctly to current AT command
            if (OBDComm2.bCommandRunning == false)
            {
                iWaitForCommand = 0;

                //Send first command: query engine temperature
                //Hier muss noch abgefragt werden, ob diese PID überhaupt unterstützt wird. TODO
                if (iCommandQuery == 0)
                {
                    iCommandQuery = 1;
                    OBDComm2.fncStartCommand("01051");
                }
                else if (iCommandQuery == 1)
                {
                    //Evaluate answer from ELM
                    var iValue = OBDDataObject.fncEvaluatePIDQuery(OBDComm2.sReceiveBuffer, "0105");
                    if (iValue !== null)
                        labelEngineTemp.text = iValue;

                    //Send next command
                    iCommandQuery = 0;
                }
            }
            else
            {
                //ELM has not yet answered. Or the answer is not complete.
                //Check if wait time is over.
                if (iWaitForCommand == 10)
                {
                    //Skip now.
                    OBDComm2.bCommandRunning = false;
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

            PageHeader { title: qsTr("OBD Drive") }

            Label
            {
                text: "Engine Temp:"
            }
            Label
            {
                id: labelEngineTemp
                text: "Tester"
            }
        }
    }
}
