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
    property bool bPushDyn1Page: true
    property int iWaitForCommand: 0
    property int iCommandSequence: 1
    property string sParameter1: "Not supported"
    property string sParameter2: "Not supported"
    property string sParameter3: "Not supported"
    property string sParameter4: "Not supported"
    property string sParameter5: "Not supported"
    property string sParameter6: "Not supported"

    onStatusChanged:
    {
        if (status === PageStatus.Active && bPushDyn1Page)
        {
            bPushDyn1Page = false;
            pageStack.pushAttached(Qt.resolvedUrl("Dyn2Page.qml"));
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
            //Check if ELM has answered correctly to current AT command
            if (bCommandRunning == false)
            {
                iWaitForCommand = 0;

                //Send first command: query engine temperature
                switch (iCommandSequence)
                {
                    case 1:
                        if (fncStartCommand("01041"))
                            iCommandSequence++;
                        else
                            iCommandSequence = iCommandSequence + 2;
                        break;
                    case 2:
                        sParameter1 = OBDDataObject.arrayLookupPID["0104"].labeltext + " " +
                                OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "0104") +
                                OBDDataObject.arrayLookupPID["0104"].unittext;
                        iCommandSequence++;
                        break;
                    case 3:
                        if (fncStartCommand("01051"))
                            iCommandSequence++;
                        else
                            iCommandSequence = iCommandSequence + 2;
                        break;
                    case 4:
                        sParameter2 = OBDDataObject.arrayLookupPID["0105"].labeltext + " " +
                                OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "0105") +
                                OBDDataObject.arrayLookupPID["0105"].unittext;
                        iCommandSequence++;
                        break;
                    case 5:
                        if (fncStartCommand("010C1"))
                            iCommandSequence++;
                        else
                            iCommandSequence = iCommandSequence + 2;
                        break;
                    case 6:
                        sParameter3 = OBDDataObject.arrayLookupPID["010c"].labeltext + " " +
                                OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "010C") +
                                OBDDataObject.arrayLookupPID["010c"].unittext;
                        iCommandSequence++;
                        break;
                    case 7:
                        if (fncStartCommand("010D1"))
                            iCommandSequence++;
                        else
                            iCommandSequence = iCommandSequence + 2;
                        break;
                    case 8:
                        sParameter4 = OBDDataObject.arrayLookupPID["010d"].labeltext + " " +
                                OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "010D") +
                                OBDDataObject.arrayLookupPID["010d"].unittext;
                        iCommandSequence++;
                        break;
                    case 9:
                        if (fncStartCommand("010E1"))
                            iCommandSequence++;
                        else
                            iCommandSequence = iCommandSequence + 2;
                        break;
                    case 10:
                        sParameter5 = OBDDataObject.arrayLookupPID["010e"].labeltext + " " +
                                OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "010E") +
                                OBDDataObject.arrayLookupPID["010e"].unittext;
                        iCommandSequence++;
                        break;
                    case 11:
                        if (fncStartCommand("01111"))
                            iCommandSequence++;
                        else
                            iCommandSequence = 1;
                        break;
                    case 12:
                        sParameter6 = OBDDataObject.arrayLookupPID["0111"].labeltext + " " +
                                OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "0111") +
                                OBDDataObject.arrayLookupPID["0111"].unittext;
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

        Column
        {
            id: id_Column_FirstCol

            spacing: Theme.paddingLarge
            width: parent.width

            PageHeader { title: qsTr("Dynamic Values 1") }

            Label
            {
                text: sParameter1;
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            Label
            {
                text: sParameter2;
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            Label
            {
                text: sParameter3;
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            Label
            {
                text: sParameter4;
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            Label
            {
                text: sParameter5;
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            Label
            {
                text: sParameter6;
            }
        }
    }
}
