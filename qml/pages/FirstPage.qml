import QtQuick 2.0
import Sailfish.Silica 1.0
import "SharedResources.js" as SharedResources
import "OBDComm.js" as OBDComm


Page {
    id: page

    property bool bFirstPage: true
    property bool bWaitForCommandSequenceEnd: false
    property int iInit: 0
    property inf iWaitForCommand: 0
    property string sELMVersion: ""

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
            progressBarInit.valueText = "Checking OBD adapter...";

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
            
                //Init first step. This is after sending ATZ
                if (iInit == 1)
                {
                    //Check if this is an ELM327
                    if (OBDComm.sReceiveBuffer.indexOf("ELM327") !== -1)
                    {
                        //This is not ELM327!!!
                        //Skip now and disconect from bluetooth device
                        fncViewMessage("error", "Unknown OBD Adapter!!!");
                        id_BluetoothData.disconnect();
                        iInit = 0;
                    }
                    else
                    {
                        //Now, this is an ELM327. So far so good.
                        //Extract the version number.
                        sELMVersion = (OBDComm.sReceiveBuffer.substr(OBDComm.sReceiveBuffer.indexOf(" v"))).trim();
                        
                        //Let's initialize this baby...
                        iInit = 2;
                        progressBarInit.valueText = "Switch echo off...";                        
                        OBDComm.fncStartCommand("ATE0");
                    }
                }
                else if (iInit == 2)
                {
                    //Just send next init command
                    iInit = 3;
                    progressBarInit.valueText = "Switch linefeed off...";                        
                    OBDComm.fncStartCommand("ATL0");
                }
                else if (iInit == 3)
                {
                    iInit = 4;
                    progressBarInit.valueText = "Switch headers off...";                        
                    OBDComm.fncStartCommand("ATH0");
                }
                else if (iInit == 4)
                {
                    iInit = 5;
                    progressBarInit.valueText = "Set protocol...";                        
                    OBDComm.fncStartCommand("ATSP0");                    
                }
                else if (iInit == 5)
                {
                    iInit = 6;
                    progressBarInit.valueText = "Supported PID's 01-20...";                    
                    OBDComm.fncStartCommand("0100");                    
                }
                else if (iInit == 6)
                {
                    iInit = 7;
                    
                    //Finish for now
                    bWaitForCommandSequenceEnd = false; 
                    
                    fncViewMessage("info", "Init is ready now!!!");
                    
                    pageStack.pushAttached(Qt.resolvedUrl("SecondPage.qml"));
                    //pageStack.navigateForward();
                    //TODO
                }                
            }
            else
            {
                //ELM has not yet answered. Or the answer is not complete.
                //Check if wait time is over.
                if (iWaitForCommand == 8)
                {
                    //Now it depends on which command we are waiting.                                       
                    if (iInit == 1)
                    {
                        //If we wait for ELM to identify itself, break and disconnect.                        
                        fncViewMessage("error", "Unknown OBD Adapter!!!");
                        iInit = 0; 
                    }
                    else if (iInit > 1 && iInit != 6)
                    {
                        //If we are in init procedure, reset init progress
                        iInit = 0; 
                    }
                    else if (iInit == 6)
                    {
                        //Here we are after the first PID request.
                        //This may last longer because the ELM needs some time to find the correct protocol.
                        
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

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader 
            {
                title: qsTr("Bluetooth OBD Scanner")
            }            
            Button
            {
                text: "Start scanning for BT devices..."
                onClicked:
                {
                    SharedResources.fncDeleteDevices();
                    id_BluetoothConnection.vStartDeviceDiscovery();
                }
            }
            Button
            {
                text: "Stop scanning for BT devices..."
                onClicked:
                {
                    id_BluetoothConnection.vStopDeviceDiscovery();
                }
            }
            Button
            {
                text: "Disconnect"
                onClicked:
                {
                    id_BluetoothData.disconnect();
                }
            }
           
            SectionHeader
            {
                id: sectionHeaderInit
                text: "Initialization"
                visible: (iInit > 0)
            }
            //First step: check if it's an ELM327
            //Second step: send 4 init commands to ELM327
            ProgressBar
            {
                id: progressBarInit
                width: parent.width
                maximumValue: 30
                valueText: value + "/" + maximumValue
                label: "Progress"
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
                        console.log("Clicked " + index);
                        id_BluetoothData.connect(SharedResources.fncGetDeviceBTAddress(index), 1);

                    }
                }
                VerticalScrollDecorator {}
            }
        }
    }
}
