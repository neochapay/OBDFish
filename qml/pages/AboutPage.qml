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

Page
{
    allowedOrientations: Orientation.All
    property int iCountWhtRbbt: 1;

    Column
    {
        anchors.top: parent.top
        width: parent.width

        PageHeader
        {
            title: qsTr("About OBDFish")
        }
        Item
        {
            width: parent.width
            height: Theme.paddingMedium
        }
        Button
        {
            anchors.horizontalCenter: parent.horizontalCenter
            height: 256
            Image
            {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "../obdfish.png"
            }
            onClicked:
            {
                if (iCountWhtRbbt == 1)
                    fncShowMessage("First iteration", 1000);
                else if (iCountWhtRbbt == 2)
                    fncShowMessage("Second iteration", 1000);
                else if (iCountWhtRbbt == 3)
                    fncShowMessage("Third iteration", 1000);
                else if (iCountWhtRbbt == 4)
                    fncShowMessage("Fourth iteration", 1000);
                else if (iCountWhtRbbt == 5)
                    fncShowMessage("Fifth iteration", 1000);
                else if (iCountWhtRbbt == 6)
                    fncShowMessage("Sixth iteration", 1000);
                else if (iCountWhtRbbt == 7)
                    fncShowMessage("Seventh iteration", 1000);
                else if (iCountWhtRbbt == 8)
                    fncShowMessage("STOP NOW or system will crash!!!", 6000);
                else if (iCountWhtRbbt == 9)
                    fncShowMessage("executing Whte_rbt.obj...", 1000);
                else if (iCountWhtRbbt == 10)
                {
                    fncShowMessage("Developed by Integrated Computer Systems, Inc. Cambnridge Mass<br>Project Supervisor: Dennis Nedry<br>Chief Programmer: Jens Drescher<br>\u00A9 Jurassic Parc Inc. All Rights Reserved", 16000);
                    iCountWhtRbbt = 1;
                }

                iCountWhtRbbt++;
            }
        }
        Label
        {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeLarge
            horizontalAlignment: Text.AlignHCenter
            text: "OBDFish"
        }
        Item
        {
            width: parent.width
            height: Theme.paddingMedium
        }
        Label
        {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("OBD ELM327 car diagnostic reader application for Sailfish OS")
        }
        Item
        {
            width: parent.width
            height: Theme.paddingLarge            
        }
        Label
        {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: "Copyright \u00A9 2016 Jens Drescher, Germany"
        }       
        Label
        {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: "Version: 1.0.0-1"
        }
        Label
        {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: qsTr("Date: 07.05.2016")
        }
        Label
        {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: qsTr("License: GPLv3")
        }
        Item
        {
            width: parent.width
            height: Theme.paddingLarge
        }
        Label
        {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: qsTr("Source code:")
        }
        Label
        {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            property string urlstring: "https://github.com/jdrescher2006/OBDFish"
            text: "<a href=\"" + urlstring + "\">" +  urlstring + "<\a>"
            onLinkActivated: Qt.openUrlExternally(link)
        }
    }
}


