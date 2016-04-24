import QtQuick 2.0
import Sailfish.Silica 1.0
import "SharedResources.js" as SharedResources
import "OBDComm.js" as OBDComm
import "OBDDataObject.js" as OBDDataObject


Page
{
    id: page

    property bool bFirstPage: true
    property bool bWaitForCommandSequenceEnd: false
    property int iInit: 0
    property int iWaitForCommand: 0   

    onStatusChanged:
    {       
        if (status === PageStatus.Active && bFirstPage)
        {
            bFirstPage = false

            //DEBUG!!!
            SharedResources.fncAddDevice("Neuer Adapter v2.1", "88:18:56:68:98:EB");
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
    }
    Connections
    {
        target: id_BluetoothData
        onSigReadDataReady:     //This is called from C++ if there is data via bluetooth
        {
            //Check received data
            OBDComm.fncGetData(sData);
        }
        onSigConnected:         //This is called from C++ if a connection was established
        {            
            fncViewMessage("info", "Connected");
            bConnected = true;

            //Now start with initialize process
            iInit = 1;
            progressBarInit.label = "Checking OBD adapter...";

            //Send command to check if this is an ELM327
            iWaitForCommand = 0;
            OBDComm.fncStartCommand("ATZ");
            bWaitForCommandSequenceEnd = true;
        }
        onSigDisconnected:      //This is called from C++ if an established bluetooth connection gets disconnected
        {
            fncViewMessage("info", "Disconnected");
            bConnected = false;
        }
        onSigError:             //This is called from C++ if there was an error while establishing a bluetooth connection
        {
            fncViewMessage("error", "Error: " + sError);
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
            if (OBDComm.bCommandRunning == false)
            {
                iWaitForCommand = 0;
            
                console.log("timWaitForCommandSequenceEnd step:  " + iInit);

                //Init first step. This is after sending ATZ
                if (iInit == 1)
                {
                    //Get rid of all the carriage returns
                    var sAnswer = OBDComm.sReceiveBuffer.replace(/\r/g, " ");

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
                        OBDDataObject.sELMVersion = (sAnswer.substr(OBDComm.sReceiveBuffer.indexOf(" v"))).trim();
                        
                        //Let's initialize this baby...
                        iInit = 2;
                        progressBarInit.label = "Switch echo off...";
                        OBDComm.fncStartCommand("ATE0");
                    }
                }
                else if (iInit == 2)
                {
                    //Just send next init command
                    iInit = 3;
                    progressBarInit.label = "Switch linefeed off...";
                    OBDComm.fncStartCommand("ATL0");
                }
                else if (iInit == 3)
                {
                    iInit = 4;
                    progressBarInit.label = "Switch headers off...";
                    OBDComm.fncStartCommand("ATH0");
                }
                else if (iInit == 4)
                {
                    iInit = 5;
                    progressBarInit.label = "Switch spaces off...";
                    OBDComm.fncStartCommand("ATS0");
                }
                else if (iInit == 5)
                {
                    iInit = 6;
                    progressBarInit.label = "Set protocol...";
                    OBDComm.fncStartCommand("ATSP0");                    
                }
                else if (iInit == 6)
                {
                    iInit = 7;
                    progressBarInit.label = "Supported PID's 0101-0120...";
                    OBDComm.fncStartCommand("0100");                    
                }
                else if (iInit == 7)
                {
                    iInit = 8;
                    //Evaluate and save answer from ELM
                    OBDDataObject.fncSetSupportedPIDs(OBDComm.sReceiveBuffer, "0100");

                    progressBarInit.label = "Supported PID's 0121-0140...";
                    OBDComm.fncStartCommand("0120");
                }
                else if (iInit == 8)
                {
                    iInit = 9;
                    //Evaluate answer from ELM
                    OBDDataObject.fncSetSupportedPIDs(OBDComm.sReceiveBuffer, "0120");

                    progressBarInit.label = "Supported PID's 0900-0920...";
                    OBDComm.fncStartCommand("0900");
                }
                else if (iInit == 9)
                {
                    iInit = 10;
                    //Evaluate answer from ELM
                    OBDDataObject.fncSetSupportedPIDs(OBDComm.sReceiveBuffer, "0900");

                    //Finish for now
                    bWaitForCommandSequenceEnd = false;

                    //Evaluate if ELM found any supported PID
                    if (OBDDataObject.fncGetFoundSupportedPIDs())
                    {
                        fncViewMessage("info", "Init is ready now!!!");
                        labelInitOutcome.text = "Masks: " + OBDDataObject.arrayOBDSupportedPIDs.length.toString();
                    }
                    else
                    {
                        fncViewMessage("error", "No supported PID's!!!");
                        labelInitOutcome.text = "Keine PID's!!!";
                    }

                    pageStack.pushAttached(Qt.resolvedUrl("SecondPage.qml"));
                    //pageStack.navigateForward();
                    //TODO
                }
            }
            else
            {
                //ELM has not yet answered. Or the answer is not complete.
                //Check if wait time is over.
                if (iWaitForCommand == 20)
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

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu 
        {
            MenuItem 
            {
                text: qsTr("Show Page 2")
                onClicked: pageStack.push(Qt.resolvedUrl("SecondPage.qml"))
            }
        }

        contentHeight: column.height

        Column
        {
            id: column

            width: parent.width
            spacing: Theme.paddingMedium
            PageHeader 
            {
                title: qsTr("Bluetooth OBD Scanner")
            }
            Row
            {
                width: parent.width

                Button
                {
                    width: parent.width/3
                    text: "Start Scan"
                    onClicked:
                    {
                        SharedResources.fncDeleteDevices();
                        id_BluetoothConnection.vStartDeviceDiscovery();
                    }
                }
                Button
                {
                    width: parent.width/3
                    text: "Stop Scan"
                    onClicked:
                    {
                        id_BluetoothConnection.vStopDeviceDiscovery();
                    }
                }
                Button
                {
                    width: parent.width/3
                    text: "Disconnect"
                    onClicked:
                    {
                        id_BluetoothData.disconnect();
                    }
                }
            }
            Label
            {
                id: labelInitOutcome
                text:""
            }


            //First step: check if it's an ELM327
            //Second step: send 4 init commands to ELM327
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
                        id_BluetoothData.connect(SharedResources.fncGetDeviceBTAddress(index), 1);
                    }
                }
                VerticalScrollDecorator {}
            }
        }
    }
}
