import QtQuick 2.0
import Sailfish.Silica 1.0
import "SharedResources.js" as SharedResources
import "OBDComm.js" as OBDComm


Page {
    id: page

    property bool bFirstPage: true
    property bool bWaitForCommandSequenceEnd: false

    onStatusChanged:
    {       
        if (status === PageStatus.Active && bFirstPage)
        {
            bFirstPage = false

            SharedResources.fncAddDevice("Neuer Adapter v2.1", "88:18:56:68:98:EB");
            SharedResources.fncAddDevice("Alter Adapter v1.5", "98:76:54:32:10:00");
            id_LV_Devices.model = SharedResources.fncGetDevicesNumber();
        }
    }

    Connections
    {
        target: id_BluetoothConnection
        onDeviceFound:
        {
            //Add device to data array
            SharedResources.fncAddDevice(sName, sAddress);
            id_LV_Devices.model = SharedResources.fncGetDevicesNumber();
        }
    }
    Connections
    {
        target: id_BluetoothData
        onSigReadDataReady:
        {
            id_LBL_ReadText.text = sData;
            OBDComm.fncGetData(sData);
        }
        onSigConnected:
        {            
            fncViewMessage("info", "Connected");
            bConnected = true;

            pageStack.pushAttached(Qt.resolvedUrl("SecondPage.qml"));
            //pageStack.navigateForward();
        }
        onSigDisconnected:
        {
            fncViewMessage("info", "Disconnected");
            bConnected = false;
        }
        onSigError:
        {
            fncViewMessage("error", "Error: " + sError);
        }
    }
    Timer
    {
        id: timWaitForCommandSequenceEnd
        interval: 200
        running: bWaitForCommandSequenceEnd
        repeat: true
        onTriggered:
        {
            //Wait until command sequence has ended
            if (!OBDComm.bCommandRunning)
            {
                if (OBDComm.bCommandOK)
                    fncViewMessage("info", "Command successful.");
                else
                    fncViewMessage("error", "Command not successful.");

                //It's weird that this is needed here...  :-(((
                id_LBL_Voltage.text = OBDComm.sVoltage;
                id_LBL_AdapterInfo.text = OBDComm.sAdapterInfo;

                bWaitForCommandSequenceEnd = false;
            }
        }
    }

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable
    {
        anchors.fill: parent

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
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
            PageHeader {
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
            Row
            {
                spacing: Theme.paddingSmall
                width: parent.width
                Button
                {
                    width: parent.width/3;
                    text: "Info"
                    onClicked:
                    {                      
                        if (!OBDComm.bCommandRunning)
                        {
                            OBDComm.fncStartCommand("adapterinfo");
                            bWaitForCommandSequenceEnd = true;
                        }
                    }
                }
                Button
                {
                    width: parent.width/3;
                    text: "Init"
                    onClicked:
                    {
                        if (!OBDComm.bCommandRunning)
                        {
                            OBDComm.fncStartCommand("init");
                            bWaitForCommandSequenceEnd = true;
                        }
                    }
                }
                Button
                {
                    width: parent.width/3;
                    text: "Voltage"
                    onClicked:
                    {
                        if (!OBDComm.bCommandRunning)
                        {
                            OBDComm.fncStartCommand("voltage");
                            bWaitForCommandSequenceEnd = true;
                        }
                    }
                }
            }
            Row
            {
                spacing: Theme.paddingSmall
                width: parent.width
                Button
                {
                    width: parent.width/3;
                    text: "L0"
                    onClicked:
                    {
                        id_BluetoothData.sendHex("AT L0");
                    }
                }
                Button
                {
                    width: parent.width/3;
                    text: "H0"
                    onClicked:
                    {
                        id_BluetoothData.sendHex("AT H0");
                    }
                }
                Button
                {
                    width: parent.width/3;
                    text: "D"
                    onClicked:
                    {
                        id_BluetoothData.sendHex("AT D");
                    }
                }
            }
            Label
            {
                width: parent.width;
                id: id_LBL_ReadText;
                text: "";
            }
            Row
            {
                spacing: Theme.paddingSmall
                width: parent.width;
                Label
                {
                    id: id_LBL_Voltage;
                    width: parent.width/3;                    
                }
                Label
                {
                    id: id_LBL_AdapterInfo;
                    width: parent.width/3;
                }
                Label
                {
                    width: parent.width/3;
                    text: OBDComm.sCommandStateMachine;
                }
            }

            SectionHeader
            {
                text: "Found Bluetooth devices:"
            }
            SilicaListView
            {
                id: id_LV_Devices
                model: SharedResources.fncGetDevicesNumber();
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height / 3

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


