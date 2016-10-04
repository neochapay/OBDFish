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
    property bool bInitPage: true

    //Properties for clearing error dialog
    property int iCommandSequenceClearDTC : 0
    property int iWaitForCommandClearDTC : 0
    property bool bWaitForCommandSequenceEndClearDTC : false

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
        id: timClearDTCError
        interval: 500
        running: bWaitForCommandSequenceEndClearDTC
        repeat: true
        onTriggered:
        {
            var sReadValue = "";

            //Check if ELM has answered correctly to current AT command
            if (bCommandRunning == false)
            {
                iWaitForCommandClearDTC = 0;

                console.log("timWaitForCommandSequenceEnd step: " + iCommandSequenceClearDTC);

                switch (iCommandSequenceClearDTC)
                {
                    case 1:
                        progressBarReadValues.label = "Clearing DTC's ...";
                        if (bSaveDataToDebugFile) id_FileWriter.vWriteData("Starting clearing error code...\r\n");
                        fncStartCommand("04")
                        iCommandSequenceClearDTC++;
                        break;
                    case 2:
                        progressBarReadValues.label = "Checking if DTC's are cleared...";
                        if (sReadValue !== null && sReadValue.indexOf("44") !== -1)
                        {
                            if (bSaveDataToDebugFile) id_FileWriter.vWriteData("Clearing error ready. Result: " + sReadValue + "\r\n");
                            fncShowMessage(2,qsTr("Trouble codes successfully cleared."), 6000);
                        }
                        else
                        {
                            if (bSaveDataToDebugFile) id_FileWriter.vWriteData("Could not error trouble codes. Result: " + sReadValue + "\r\n");
                            fncShowMessage(3,qsTr("Could not clear trouble codes."), 6000);
                        }

                        bWaitForCommandSequenceEndClearDTC = false; //Finish by halting timer
                        break;
                }
            }
            else
            {
                //ELM has not yet answered. Or the answer is not complete.
                //Check if wait time is over.
                if (iWaitForCommandClearDTC == 100)
                {
                    iCommandSequenceClearDTC = 0;
                    bWaitForCommandSequenceEndClearDTC = false;
                    fncViewMessage("error", "Communication timeout!!!");
                }
                else
                    iWaitForCommandClearDTC++;
            }
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
                        progressBarReadValues.label = "Reading DTC infos...";
                        if (fncStartCommand("01011"))
                            iCommandSequence++;
                        else
                            //The requesting of DTC's is not supported.
                            //Show this in a message and don't do anything further.
                            bNotSupported = true;
                        break;
                    case 2:
                        sReadValue = OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "0101");

                        //DEBUG: typical answer would be: 41 01 81 07 65 04
                        //DEBUG: MIL is set and number of errors is 1.
                        //sReadValue = OBDDataObject.fncEvaluatePIDQuery("410181076504", "0101");

                        //console.log("sReadValue: " + sReadValue);
                        //console.log("03 supported: " + OBDDataObject.arrayLookupPID["03"].supported.toString());

                        //Error LED is ON if PID 03 is supported.
                        //This was set by requesting 0101.
                        if (sReadValue !== null && OBDDataObject.arrayLookupPID["03"].supported)
                        {
                            progressBarReadValues.label = "Checking DTC infos...";

                            //Check answer string, e.g. "On, 2" or "Off, 0"
                            var sSplitString = sReadValue.split(',');                            

                            sNumberOfErrors = sSplitString[1].trim();

                            var sFirstString = qsTr("Your vehicle has ");
                            var sSecondString = qsTr(" errors!");

                            id_LABEL_ErrorNumber.text = sFirstString + sNumberOfErrors + sSecondString;

                            iCommandSequence++;
                        }
                        else
                        {
                            //Error LED is OFF. Don't do anything further. Number of errors is obviously 0.
                            sNumberOfErrors = "0";
                            //End sequence here.
                            bWaitForCommandSequenceEnd = false; //Finish by halting timer
                        }

                        break;
                    case 3:
                        progressBarReadValues.label = "Reading DTC codes...";
                        fncStartCommand("03" + OBDDataObject.arrayLookupPID["03"].bytescount.toString())
                        iCommandSequence++;

                        break;
                    case 4:
                        progressBarReadValues.label = "Checking DTC codes...";
                        //Typical response for 03 request: 43013300000000      -> P0133
                                                         //43010211201220\r43151415150000
                                                         //43010201130315

                        sReadValue = OBDDataObject.fncEvaluateDTCQuery(sReceiveBuffer);

                        //DEBUG
                        //sReadValue = OBDDataObject.fncEvaluateDTCQuery("43010211200000");

                        sDTCString = sReadValue;

                        bWaitForCommandSequenceEnd = false; //Finish by halting timer
                        console.log("Error reading ready!");
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

        PullDownMenu
        {
            MenuItem
            {
                text: qsTr("Refresh")
                onClicked:
                {
                    bNotSupported = false;
                    sNumberOfErrors = "";
                    sDTCString = "";

                    //Now start with reading error data from ELM
                    iCommandSequence = 1;
                    iWaitForCommand = 0;
                    bWaitForCommandSequenceEnd = true;
                }
            }
        }
        Column
        {
            id: id_Column_FirstCol

            spacing: Theme.paddingMedium
            width: parent.width

            PageHeader { title: qsTr("Error Informations") }

            ProgressBar
            {
                id: progressBarReadValues
                width: parent.width
                visible: bWaitForCommandSequenceEnd || bWaitForCommandSequenceEndClearDTC
                indeterminate: true
                label: qsTr("Reading values...")
            }

            Label
            {
                visible: bNotSupported
                width: parent.width
                text: qsTr("Your vehicle does not support the reading of errors.");
            }


            Image
            {
                id: id_Image_OBDOK                
                visible: (!bNotSupported && bWaitForCommandSequenceEnd === false && sNumberOfErrors === "0" && sNumberOfErrors !== "")
                anchors.horizontalCenter: parent.horizontalCenter
                height: 100
                fillMode: Image.PreserveAspectFit
                source: "../obd_ok.png"
            }
            Image
            {
                id: id_Image_OBDERROR
                visible: (!bNotSupported && bWaitForCommandSequenceEnd === false && sNumberOfErrors !== "0" && sNumberOfErrors !== "")
                anchors.horizontalCenter: parent.horizontalCenter
                height: 100
                fillMode: Image.PreserveAspectFit
                source: "../obd_error.png"
            }
            Item
            {
                width: parent.width
                height: Theme.paddingLarge
            }

            Label
            {
                visible: (!bNotSupported && bWaitForCommandSequenceEnd === false && sNumberOfErrors === "0" && sNumberOfErrors !== "")
                width: parent.width
                text: qsTr("No errors found!");
            }
            Label
            {
                id: id_LABEL_ErrorNumber
                visible: (!bNotSupported && bWaitForCommandSequenceEnd === false && sNumberOfErrors !== "0" && sNumberOfErrors !== "")
                width: parent.width
            }

            Separator {color: Theme.highlightColor; width: parent.width; visible: (!bNotSupported && bWaitForCommandSequenceEnd === false && sNumberOfErrors !== "0" && sNumberOfErrors !== "")}

            Label
            {
                visible: (!bNotSupported && bWaitForCommandSequenceEnd === false && sNumberOfErrors !== "0" && sNumberOfErrors !== "")
                width: parent.width
                text: qsTr("Error ID's: \r\n") + sDTCString;
            }            
            Separator {color: Theme.highlightColor; width: parent.width; visible: (!bNotSupported && bWaitForCommandSequenceEnd === false && sNumberOfErrors !== "0" && sNumberOfErrors !== "");}
            Label
            {
                visible: (!bNotSupported && bWaitForCommandSequenceEnd === false && sNumberOfErrors !== "0" && sNumberOfErrors !== "")
                width: parent.width
                text: qsTr("Error codes:")
            }
            Label
            {
                visible: (!bNotSupported && bWaitForCommandSequenceEnd === false && sNumberOfErrors !== "0" && sNumberOfErrors !== "")
                width: parent.width
                property string urlstring: "http://www.obd-codes.com/trouble_codes/"
                text: "<a href=\"" + urlstring + "\">" +  urlstring + "<\a>"
                onLinkActivated: Qt.openUrlExternally(link);
            }
            Item
            {
                width: parent.width
                height: Theme.paddingLarge
            }
            Button
            {
                visible: (!bNotSupported && bWaitForCommandSequenceEnd === false && sNumberOfErrors !== "0" && sNumberOfErrors !== "")
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Clear Trouble Codes")
                onClicked:
                {
                    if (bDoNotShowDTCWarning)
                    {
                        //Start command sequence for clearing DTC error
                        iCommandSequenceClearDTC = 1;
                        iWaitForCommandClearDTC = 0;
                        bWaitForCommandSequenceEndClearDTC = true;
                    }
                    else
                        pageStack.push(dialogClearDTCError);
                }
            }

            Component
            {
                id: dialogClearDTCError

                Dialog
                {
                    onStatusChanged:
                    {
                        if (status === PageStatus.Active)
                        {
                            console.log("onStatusChanged: dialogClearDTCError Active");

                            bInitPage = true;
                            id_TextSwitch_DoNotShowAgain.checked = bDoNotShowDTCWarning;
                            bInitPage = false;
                        }

                        //Save values to project data when page is closed
                        if (status === PageStatus.Deactivating && !bInitPage)
                        {
                            console.log("onStatusChanged: dialogClearDTCError Deactivating");

                            //Check if fields are valid and have changed
                            if (bDoNotShowDTCWarning != id_TextSwitch_DoNotShowAgain.checked)
                            {
                                bDoNotShowDTCWarning = id_TextSwitch_DoNotShowAgain.checked;
                                id_ProjectSettings.vSaveProjectData("DoNotShowDTCWarning", id_TextSwitch_DoNotShowAgain.checked.toString());
                            }
                        }
                    }

                    allowedOrientations: Orientation.All

                    onAccepted:
                    {
                        //Start command sequence for clearing DTC error
                        iCommandSequenceClearDTC = 1;
                        iWaitForCommandClearDTC = 0;
                        bWaitForCommandSequenceEndClearDTC = true;
                    }
                    Flickable
                    {
                        width: parent.width
                        height: parent.height
                        interactive: false

                        Column
                        {
                            width: parent.width

                            DialogHeader
                            {
                                title: qsTr("Are you sure?")
                            }

                            Image
                            {
                                fillMode: Image.PreserveAspectFit
                                source: "image://theme/icon-l-attention"
                            }
                            Label
                            {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: qsTr("NOTE: if you proceed, all trouble code information is immediately lost!<br>Your vehicle may run poorly for a short time, while it performs a recalibration.")
                            }
                            TextSwitch
                            {
                                id: id_TextSwitch_DoNotShowAgain
                                text: qsTr("Do not show this again")
                                description: qsTr("Do not show this warning again.")
                            }
                        }
                    }
                }
            }
        }
    }
}
