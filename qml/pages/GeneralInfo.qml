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
    id: id_page_generalinfo
    property bool bPushGeneralInfoPage: true
    property int iCommandSequence: 0
    property bool bWaitForCommandSequenceEnd: false
    property int iWaitForCommand: 0
    property string sOBDStandard: "Not supported"
    property string sOBDProtocol: "Not supported"
    property string sFuelType: "Not supported"
    property string sVIN: "Not supported"
    property string sBatteryVoltage: ""


    onStatusChanged:
    {
        if (status === PageStatus.Active && bPushGeneralInfoPage)
        {
            bPushGeneralInfoPage = false;
            pageStack.pushAttached(Qt.resolvedUrl("Dyn1Page.qml"));

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
        interval: 125
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
                        if (fncStartCommand("011C1"))
                            iCommandSequence++;
                        else
                            iCommandSequence = iCommandSequence + 2;
                        break;
                    case 2:
                        sReadValue = OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "011C");
                        if (sReadValue !== null)
                            sOBDStandard = sReadValue;
                        iCommandSequence++;
                        break;
                    case 3:
                        if (fncStartCommand("01511"))                        
                            iCommandSequence++;                                                   
                        else                       
                            iCommandSequence = iCommandSequence + 2;                        
                        break;
                    case 4:
                        sReadValue = OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "0151");
                        if (sReadValue !== null)
                            sFuelType = sReadValue;
                        iCommandSequence++;
                        break;
                    case 5:
                        if (fncStartCommand("ATDP"))
                            iCommandSequence++;
                        else
                            iCommandSequence = iCommandSequence + 2;
                        break;
                    case 6:
                        sOBDProtocol = sReceiveBuffer;
                        iCommandSequence++;
                        break;
                    case 7:
                        if (fncStartCommand("ATRV"))
                            iCommandSequence++;
                        else
                            iCommandSequence = iCommandSequence + 2;
                        break;
                    case 8:
                        sBatteryVoltage = sReceiveBuffer;
                        iCommandSequence++;
                        break;
                    case 9:
                        if (fncStartCommand("09011"))
                            iCommandSequence++;
                        else
                            iCommandSequence = iCommandSequence + 2;
                        break;
                    case 10:
                        sReadValue = OBDDataObject.fncEvaluatePIDQuery(sReceiveBuffer, "0901");
                        iCommandSequence++;
                        break;
                    case 11:
                        //Need this for VIN query.
                        //Disable adaptive timing of ELM.
                        fncStartCommand("ATAT0");
                        iCommandSequence++;
                        break;
                    case 12:
                        //Set very high timeout. Also needed for VIN query.
                        fncStartCommand("ATST128");
                        iCommandSequence++;
                        break;
                    case 13:
                        //The number behind the PID is the number of packets expected from ELM
                        if (fncStartCommand("09025"))
                            iCommandSequence++;
                        else
                            iCommandSequence = iCommandSequence + 2;
                        break;
                    case 14:
                        sReadValue = OBDDataObject.fncEvaluateVINQuery(sReceiveBuffer);

                        var sVINString = sReadValue.match(new RegExp('.{1,2}', 'g'));
                        var sReturnVIN = "";
                        sVINString.forEach(function(sHex)
                        {
                            console.log("sHex: " + sHex);

                            var sTester = parseInt(sHex, 16).toString();

                            console.log("sTester: " + sTester);

                            sTester = id_BluetoothData.convertHex2Unicode(sTester);

                            //So ein Scheiss, das funktioniert nicht in QML!!!
                            //String.fromCharCode(sTester);

                            console.log("sTester: " + sTester);

                            sReturnVIN = sReturnVIN + id_BluetoothData.convertHex2Unicode(sTester);
                        });
                        sVIN = sReturnVIN;
                        iCommandSequence++;
                        break;
                    case 15:
                        if (fncStartCommand("ATST128"))
                            iCommandSequence++;
                        else
                            iCommandSequence = iCommandSequence + 2;
                        break;
                    case 16:
                        fncStartCommand("ATAT1");
                        //End sequence here.
                        bWaitForCommandSequenceEnd = false; //Finish by halting timer
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

            PageHeader { title: qsTr("General Informations") }

            Separator {color: Theme.highlightColor; width: parent.width;}
            Label
            {
                width: parent.width
                text: qsTr("OBD adapter: ELM327 ") + sELMVersion;
            }
            Separator {color: Theme.highlightColor; width: parent.width;}
            Label
            {
                width: parent.width
                text: qsTr("OBD standard: ") + sOBDStandard;
            }
            Separator {color: Theme.highlightColor; width: parent.width;}
            Label
            {
                width: parent.width
                text: qsTr("OBD protocol: ") + sOBDProtocol;
            }
            Separator {color: Theme.highlightColor; width: parent.width;}
            Label
            {
                width: parent.width
                text: qsTr("Battery voltage: ") + sBatteryVoltage + "V";
            }
            Separator {color: Theme.highlightColor; width: parent.width;}
            Label
            {
                width: parent.width
                text: qsTr("Fuel type: ") + sFuelType;
            }
            Separator {color: Theme.highlightColor; width: parent.width;}
            Label
            {
                width: parent.width
                text: qsTr("Vehicle Identification Number: <br>") + sVIN;
            }
            Separator {color: Theme.highlightColor; width: parent.width;}
            Label
            {
                width: parent.width
                property string urlstring: "https://en.wikipedia.org/wiki/OBD-II_PIDs#Mode_01"
                text: "Supported PID's, <a href=\"" + urlstring + "\">" +  "Mode 01:" + "<\a>"
                onLinkActivated: Qt.openUrlExternally(link)
            }
            Label
            {
                width: parent.width
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.WordWrap
                text: OBDDataObject.sSupportedPIDs0100;
            }
            Separator {color: Theme.highlightColor; width: parent.width;}
            Label
            {
                width: parent.width
                property string urlstring: "https://en.wikipedia.org/wiki/OBD-II_PIDs#Mode_09"
                text: "Supported PID's, <a href=\"" + urlstring + "\">" +  "Mode 09:" + "<\a>"
                onLinkActivated: Qt.openUrlExternally(link)
            }
            Label
            {
                width: parent.width
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.WordWrap
                text: OBDDataObject.sSupportedPIDs0900;
            }
            Separator {color: Theme.highlightColor; width: parent.width;}
        }
    }
}
