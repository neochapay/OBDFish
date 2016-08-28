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
    id: id_page_errorinfo
    property bool bPushErrorInfoPage: true
    property bool bNotSupported: false
    property string sNumberOfErrors: ""
    property string sDTCString: ""
    property int iCommandSequence: 0
    property bool bWaitForCommandSequenceEnd: false
    property int iWaitForCommand: 0



    onStatusChanged:
    {
        if (status === PageStatus.Active && bPushErrorInfoPage)
        {
            bPushErrorInfoPage = false;

            //Now start with reading static data from ELM
            iCommandSequence = 1;
            iWaitForCommand = 0;
            bWaitForCommandSequenceEnd = true;
        }
    }

    Timer
    {
        //This is called, everytime an AT command is send.
        //The timer waits for ELM to answer the command.
        id: timWaitForCommandSequenceEnd
        interval: 250
        running: bWaitForCommandSequenceEnd
        repeat: true
        onTriggered:
        {
            var sReadValue = "";

            //Check if ELM has answered correctly to current AT command
            if (bCommandRunning == false)
            {
                iWaitForCommand = 0;

                console.log("timWaitForCommandSequenceEnd step: " + iCommandSequence);

                switch (iCommandSequence)
                {
                    case 1:
                        if (fncStartCommand("01011"))
                            iCommandSequence++;
                        else
                            //The requesting of DTC's is not supported.
                            //Show this in a message and don't do anything further.
                            bNotSupported = true;
                        break;
                    case 2:
                        sReadValue = OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "0101");

                        //WARNING: THIS IS DEBUG -> REMOVE!!!
                        //DEBUG: typical answer would be: 41 01 81 07 65 04
                        //DEBUG: MIL is set and number of errors is 1.
                        sReadValue = OBDDataObject.fncEvaluatePIDQuery("410181076504", "0101");

                        //Error LED is ON if PID 03 is supported.
                        //This was set by requesting 0101.
                        if (sReadValue !== null && OBDDataObject.arrayLookupPID["03"].supported)
                        {
                            //Check answer string, e.g. "On, 2" or "Off, 0"
                            var sSplitString = sReadValue.split(',');
                            sNumberOfErrors = sSplitString[1].trim();

                            iCommandSequence++;
                        }
                        else
                        {
                            //Error LED is OFF. Don't do anything further.

                            //End sequence here.
                            bWaitForCommandSequenceEnd = false; //Finish by halting timer
                        }

                        break;
                    case 3:
                        fncStartCommand("03" + OBDDataObject.arrayLookupPID["03"].bytescount.toString())
                        iCommandSequence++;

                        break;
                    case 4:
                        //Typical response for 03 request: 43 013300000000      -> P0133
                                                         //43 0102 1120 1220 \r43 1514 1515 0000
                                                         //43 010201130315

                        sReadValue = OBDDataObject.fncEvaluateDTCQuery(sReceiveBuffer);

                        sReadValue = OBDDataObject.fncEvaluateDTCQuery("43013300000000");

                        sDTCString = sReadValue;

                        if (sReadValue !== null)
                        {
                            //Split the errors by ,
                            //sDTCString = sReadValue.split(',');



                            //End sequence here.
                            bWaitForCommandSequenceEnd = false; //Finish by halting timer
                        }
                        else
                        {

                        }
                        break;
                }
            }            
            else
            {
                //ELM has not yet answered. Or the answer is not complete.
                //Check if wait time is over.
                if (iWaitForCommand == 100)
                {
                    iCommandSequence = 0;
                    bWaitForCommandSequenceEnd = false;
                    fncViewMessage("error", "Communication timeout!!!");
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

            spacing: Theme.paddingMedium
            width: parent.width

            PageHeader { title: qsTr("Error Informations") }

            Label
            {
                visible: bNotSupported
                width: parent.width
                text: qsTr("Your vehicle does not support the reading of errors.");
            }
            Separator {color: Theme.highlightColor; width: parent.width; visible: !bNotSupported;}
            Label
            {
                visible: !bNotSupported
                width: parent.width
                text: qsTr("Errors: ") + sNumberOfErrors;
            }
            Separator {color: Theme.highlightColor; width: parent.width; visible: !bNotSupported;}
            Label
            {
                visible: !bNotSupported
                width: parent.width
                text: qsTr("Error ID's: ") + sDTCString;
            }            
            Separator {color: Theme.highlightColor; width: parent.width; visible: !bNotSupported;}
            Label
            {
                visible: !bNotSupported
                width: parent.width
                property string urlstring: "http://www.obd-codes.com/trouble_codes/"
                text: "Error codes, <a href=\"" + urlstring + "\"><\a>"
                onLinkActivated: Qt.openUrlExternally(link);
            }            
        }
    }
}
