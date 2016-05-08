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
import "SharedResources.js" as SharedResources
import "OBDDataObject.js" as OBDDataObject


Page
{
    id: id_page_mainpage

    property bool bFirstPage: true
    property bool bWaitForCommandSequenceEnd: false
    property int iInit: 0
    property int iWaitForCommand: 0   
    property bool bBluetoothScanning: false

    onStatusChanged:
    {       
        if (status === PageStatus.Active && bFirstPage)
        {
            bFirstPage = false

            //DEBUG!!!
            SharedResources.fncAddDevice("Neuer Adapter v1.5", "12:34:56:88:C7:B1");
            SharedResources.fncAddDevice("Adapter v2.1", "88:18:56:68:98:EB");
            SharedResources.fncAddDevice("Alter Adapter v1.5", "98:76:54:32:10:00");
            id_LV_Devices.model = SharedResources.fncGetDevicesNumber();
        }
    }

    Connections
    {
        target: id_BluetoothConnection
        onDeviceFound:      //This is called from C++ if a bluetooth device was found
        {
            //Add device to data array
            SharedResources.fncAddDevice(sName, sAddress);
            id_LV_Devices.model = SharedResources.fncGetDevicesNumber();
        }
        onScanFinished:
        {
            //Scan is finished now
            bBluetoothScanning = false;
        }
    }
    Connections
    {
        target: id_BluetoothData        
        onSigConnected:         //This is called from C++ if a connection was established
        {            
            fncViewMessage("info", "Connected");
            bConnected = true;
            bConnecting = false;

            //Now start with initialize process
            iInit = 1;
            progressBarInit.label = "Checking OBD adapter...";

            //Send command to check if this is an ELM327
            iWaitForCommand = 0;
            fncStartCommand("ATZ");
            bWaitForCommandSequenceEnd = true;
        }
        onSigDisconnected:      //This is called from C++ if an established bluetooth connection gets disconnected
        {
            fncViewMessage("info", "Disconnected");
            bConnected = false;
            bConnecting = false;
        }
        onSigError:             //This is called from C++ if there was an error while establishing a bluetooth connection
        {
            fncViewMessage("error", "Error: " + sError);
            bConnecting = false;
        }
    }
    Timer
    {
        //This is called, everytime an AT command is send.
        //The timer waits for ELM to answer the command.
        id: timWaitForCommandSequenceEnd
        interval: 200
        running: bWaitForCommandSequenceEnd
        repeat: true
        onTriggered:
        {
            //Check if ELM has answered correctly to current AT command
            if (bCommandRunning == false)
            {
                iWaitForCommand = 0;
            
                console.log("timWaitForCommandSequenceEnd step:  " + iInit);

                //Init first step. This is after sending ATZ
                if (iInit == 1)
                {
                    //Get rid of all the carriage returns
                    var sAnswer = sReceiveBuffer.replace(/\r/g, " ");

                    //Check if this is an ELM327
                    if (sAnswer.indexOf("ELM327") === -1)
                    {
                        //This is not ELM327!!!
                        //Skip now and disconect from bluetooth device
                        fncViewMessage("error", "Unknown OBD Adapter!!!");
                        id_BluetoothData.disconnect();
                        bWaitForCommandSequenceEnd = false;
                        iInit = 0;
                    }
                    else
                    {
                        //Now, this is an ELM327. So far so good.
                        //Extract the version number.
                        sELMVersion = (sAnswer.substr(sReceiveBuffer.indexOf(" v"))).trim();
                        
                        //Let's initialize this baby...
                        iInit = 2;
                        progressBarInit.label = "Switch echo off...";
                        fncStartCommand("ATE0");
                    }
                }
                else if (iInit == 2)
                {
                    //Just send next init command
                    iInit = 3;
                    progressBarInit.label = "Switch linefeed off...";
                    fncStartCommand("ATL0");
                }
                else if (iInit == 3)
                {
                    iInit = 4;
                    progressBarInit.label = "Switch headers off...";
                    fncStartCommand("ATH0");
                }
                else if (iInit == 4)
                {
                    iInit = 5;
                    progressBarInit.label = "Switch spaces off...";
                    fncStartCommand("ATS0");
                }
                else if (iInit == 5)
                {
                    iInit = 6;
                    progressBarInit.label = "Set protocol...";
                    fncStartCommand("ATSP0");
                }
                else if (iInit == 6)
                {
                    iInit = 7;
                    progressBarInit.label = "Supported PID's 0101-0120...";
                    fncStartCommand("0100");
                }
                else if (iInit == 7)
                {
                    iInit = 8;
                    //Evaluate and save answer from ELM
                    OBDDataObject.fncSetSupportedPIDs(sReceiveBuffer, "0100");

                    progressBarInit.label = "Supported PID's 0121-0140...";
                    fncStartCommand("0120");
                }
                else if (iInit == 8)
                {
                    iInit = 9;
                    //Evaluate answer from ELM
                    OBDDataObject.fncSetSupportedPIDs(sReceiveBuffer, "0120");

                    progressBarInit.label = "Supported PID's 0900-0920...";
                    fncStartCommand("0900");
                }
                else if (iInit == 9)
                {
                    iInit = 10;
                    //Evaluate answer from ELM
                    OBDDataObject.fncSetSupportedPIDs(sReceiveBuffer, "0900");

                    //Finish for now
                    bWaitForCommandSequenceEnd = false;

                    //Evaluate if ELM found any supported PID
                    if (OBDDataObject.fncGetFoundSupportedPIDs())
                    {
                        fncViewMessage("info", "Init is ready now!!!");                        
                    }
                    else
                    {
                        //fncViewMessage("error", "No supported PID's!!!");
                        fncShowMessage("No supported PID's! Either turn on ignition/engine or your OBD adapter is faulty!", 10000);
                        id_BluetoothData.disconnect();
                        bWaitForCommandSequenceEnd = false;
                        iInit = 0;
                    }

                    pageStack.pushAttached(Qt.resolvedUrl("GeneralInfo.qml"));
                    //pageStack.navigateForward();
                    //TODO
                }
            }
            else
            {
                //ELM has not yet answered. Or the answer is not complete.
                //Check if wait time is over.
                if (iWaitForCommand == 40)
                {
                    //Now it depends on which command we are waiting.                                       
                    if (iInit == 1)
                    {
                        //If we wait for ELM to identify itself, break and disconnect.                        
                        fncViewMessage("error", "Unknown OBD Adapter!!!");
                        iInit = 0; 
                    }
                    else if (iInit > 1)
                    {
                        //If we are in init procedure, reset init progress
                        iInit = 0; 
                    }                    
                    
                    //Skip now and disconect from bluetooth device                       
                    bWaitForCommandSequenceEnd = false;                        
                    fncViewMessage("error", "Communication timeout!!!");
                    id_BluetoothData.disconnect();                                        
                }
                else
                    iWaitForCommand++;
            }            
        }
    }


    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable
    {
        anchors.fill: parent
        contentHeight: id_Column_FirstCol.height + Theme.paddingLarge;

        PullDownMenu
        {
            MenuItem
            {
                text: qsTr("About")
                onClicked: {pageStack.push(Qt.resolvedUrl("AboutPage.qml"))}
            }
        }
        Column
        {
            id: id_Column_FirstCol

            width: parent.width
            spacing: Theme.paddingMedium
            PageHeader 
            {
                title: qsTr("Welcome to OBDFish")
            }

            SectionHeader
            {
                text: qsTr("Scan for Bluetooth devices...")
            }
            Button
            {
                width: parent.width
                text: qsTr("Start Scanning...")
                visible: !bBluetoothScanning && !bConnecting && !bConnected
                onClicked:
                {
                    bBluetoothScanning = true;
                    SharedResources.fncDeleteDevices();
                    id_LV_Devices.model = SharedResources.fncGetDevicesNumber();
                    id_BluetoothConnection.vStartDeviceDiscovery();
                }
                Image
                {
                    anchors.verticalCenter: parent.verticalCenter
                    source: "image://theme/icon-m-bluetooth"
                }
            }
            Button
            {
                width: parent.width
                text: qsTr("Cancel")
                visible: bBluetoothScanning
                onClicked:
                {
                    id_BluetoothConnection.vStopDeviceDiscovery();
                }
                Image
                {
                    source: "image://theme/icon-m-sync"
                    anchors.verticalCenter: parent.verticalCenter
                    smooth: true
                    NumberAnimation on rotation
                    {
                      running: bBluetoothScanning
                      from: 0
                      to: 360
                      loops: Animation.Infinite
                      duration: 2000
                    }
                }
            }
            Button
            {
                width: parent.width
                text: qsTr("Disconnect")
                visible: bConnected
                onClicked:
                {
                    //Save received data to file
                    id_FileWriter.vWriteData(sDebugFileBuffer);
                    id_BluetoothData.disconnect();
                }
                Image
                {
                    anchors.verticalCenter: parent.verticalCenter
                    source: "image://theme/icon-m-dismiss"
                }
            }           

            ProgressBar
            {
                id: progressBarConnectBT
                width: parent.width
                visible: bConnecting
                indeterminate: true
                label: "Connecting to OBD adapter..."
            }
            ProgressBar
            {
                id: progressBarInit
                width: parent.width
                maximumValue: 10
                valueText: value + "/" + maximumValue
                label: ""
                visible: (iInit > 0)
                value: iInit
            }

            SectionHeader
            {
                text: "Found Bluetooth devices:"
                visible: true
            }
            SilicaListView
            {
                id: id_LV_Devices
                model: SharedResources.fncGetDevicesNumber();
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height / 3
                visible: true

                delegate: BackgroundItem
                {
                    id: delegate

                    Label
                    {
                        x: Theme.paddingLarge
                        text: SharedResources.fncGetDeviceBTName(index) + ", " + SharedResources.fncGetDeviceBTAddress(index);
                        anchors.verticalCenter: parent.verticalCenter
                        color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }
                    onClicked:
                    {
                        //Connect here. Prepeare some things.
                        OBDDataObject.sSupportedPIDs0100 = "";
                        sDebugFileBuffer= "";
                        sELMVersion= "";
                        bConnecting = true;

                        id_BluetoothData.connect(SharedResources.fncGetDeviceBTAddress(index), 1);
                    }
                }
                VerticalScrollDecorator {}
            }
        }
    }
}
