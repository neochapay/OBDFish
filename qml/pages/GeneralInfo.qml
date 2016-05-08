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
    property string sVoltage: ""

    onStatusChanged:
    {
        if (status === PageStatus.Active && bPushGeneralInfoPage)
        {
            bPushGeneralInfoPage = false;
            pageStack.pushAttached(Qt.resolvedUrl("SecondPage.qml"));
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

            spacing: Theme.paddingSmall
            width: parent.width

            PageHeader { title: qsTr("General Informations") }

            Label
            {
                width: parent.width
                text: qsTr("OBD Adapter: ") + sELMVersion;
            }
            Label
            {
                width: parent.width
                text: qsTr("Battery Voltage: ") + sVoltage + "V";
            }
            Label
            {
                width: parent.width
                text: qsTr("Supported PID's, Mode 01:");
            }
            Label
            {
                width: parent.width
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.WordWrap
                text: OBDDataObject.sSupportedPIDs0100;
            }
        }
    }
}
