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
import "pages"
import org.nemomobile.notifications 1.0
import bluetoothconnection 1.0
import bluetoothdata 1.0

ApplicationWindow
{
    //Define global variables
    property bool bConnected: false;

    //Init C++ classes, libraries
    BluetoothConnection{ id: id_BluetoothConnection }
    BluetoothData{ id: id_BluetoothData }
    Notification { id: mainPageNotification }

    //Define global functions
    function fncViewMessage(sCategory, sMessage)
    {
        mainPageNotification.category = (sCategory === "error")
            ? "x-sailfish.sailfish-utilities.error"
            : "x-sailfish.sailfish-utilities.info";
        mainPageNotification.previewBody = "MythOBD";
        mainPageNotification.previewSummary = sMessage;
        mainPageNotification.close();
        mainPageNotification.publish();
    }

    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.All
    _defaultPageOrientations: Orientation.All
}


