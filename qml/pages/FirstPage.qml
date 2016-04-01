import QtQuick 2.0
import Sailfish.Silica 1.0
import "SharedResources.js" as SharedResources


Page {
    id: page

    property bool bFirstPage: true

    onStatusChanged:
    {
        console.log("onStatusChanged");

        if (status === PageStatus.Active && bFirstPage)
        {
            bFirstPage = false

            console.log("PageStatus.Active");

            SharedResources.fncAddDevice("Neuer Adapter", "88:18:56:68:98:EB");
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
        }
        onSigConnected:
        {
            fncViewMessage("info", "Connected to OBD");
        }
        onSigDisconnected:
        {
            fncViewMessage("info", "Disconnected from OBD");
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
                    text: "ATZ"
                    onClicked:
                    {
                        id_BluetoothData.sendHex("ATZ");
                    }
                }
                Button
                {
                    width: parent.width/3;
                    text: "No LF"
                    onClicked:
                    {
                        id_BluetoothData.sendHex("AT L0");
                    }
                }
                Button
                {
                    width: parent.width/3;
                    text: "Voltage"
                    onClicked:
                    {
                        id_BluetoothData.sendHex("AT RV");
                    }
                }
            }
            Label
            {
                id: id_LBL_ReadText;
                text: "";
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


