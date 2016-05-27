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
import "SettingsDataObject.js" as SettingsDataObject

Page
{
    allowedOrientations: Orientation.All
    property bool bPushSettingsPage: true
    property bool bInitPage: true
    property bool bPageInitialized: false
    property variant arComboboxStringArray : []    

    function fncOnComboboxCompleted()
    {
        bPageInitialized = true;

        //Here we collect all PID labels in one string array.
        //This is then the data model for the comboboxes.
        var arComboarray = ["None"];
        for (var i = 0; i < OBDDataObject.arrayPIDs.length; i++)
        {
            if (OBDDataObject.arrayPIDs[i].labeltext !== null)
            {
                arComboarray.push(OBDDataObject.arrayPIDs[i].labeltext);
                SettingsDataObject.arPIDarray.push({text: OBDDataObject.arrayPIDs[i].labeltext, pid: OBDDataObject.arrayPIDs[i].pid, index: (i + 1)});
            }
        }

        //Fill lookup arrays. Can find entrys based on PID or INDEX as key.
        console.log("lenth: " + SettingsDataObject.arPIDarray.length.toString());

        for (var j = 0; j < SettingsDataObject.arPIDarray.length; j++)
        {
            SettingsDataObject.arLookupPID[SettingsDataObject.arPIDarray[j].pid] = SettingsDataObject.arPIDarray[j];
            SettingsDataObject.arLookupINDEX[SettingsDataObject.arPIDarray[j].index] = SettingsDataObject.arPIDarray[j];
        }

        console.log(SettingsDataObject.arLookupPID["0111"].index);
        console.log(SettingsDataObject.arLookupINDEX[5].text);

        //Generate array for the start index of the copmboboxes
        SettingsDataObject.arPIDsPage1 = sPIDsPage1.split(",");

        arComboboxStringArray = arComboarray;
    }

    function fncTester()
    {
        //console.log("Tester");
    }

    onStatusChanged:
    {
        if (status === PageStatus.Active && bPushSettingsPage)
        {
            bInitPage = true;
            bPushSettingsPage = false;

            bInitPage = false;
        }

        //Save values to project data when page is closed
        if (status === PageStatus.Deactivating && !bInitPage)
        {
            //Check if fields are valid and have changed. Save values.

        }
    }

    SilicaFlickable
    {
        anchors.fill: parent
        contentHeight: id_Column_Main.height

        VerticalScrollDecorator {}

        Column
        {
            id: id_Column_Main

            spacing: Theme.paddingMedium
            width: parent.width

            PageHeader { title: qsTr("Settings") }

            SectionHeader
            {
                text: qsTr("Dynamic Parameters Page 1")
            }

            ComboBox
            {
                id: id_CMB_page1_1
                width: parent.width
                label: 'Parameter1:'                
                menu: ContextMenu { Repeater { model: arComboboxStringArray; MenuItem { text: modelData }}}
                Component.onCompleted:
                {
                    if (bPageInitialized===false) fncOnComboboxCompleted();

                    console.log(SettingsDataObject.arLookupPID[SettingsDataObject.arPIDsPage1[0]].index);
                    console.log(SettingsDataObject.arLookupPID[SettingsDataObject.arPIDsPage1[0]].index.toString());

                    //currentIndex = SettingsDataObject.arLookupPID[SettingsDataObject.arPIDsPage1[0]].index;
                    //currentIndex = 5;
                }
                onCurrentIndexChanged:
                {
                    console.log("1 changed: " + currentIndex.toString());
                }
            }

            ComboBox
            {
                id: id_CMB_page1_2
                width: parent.width
                label: 'Parameter2:'
                menu: ContextMenu { Repeater { model: arComboboxStringArray; MenuItem { text: modelData } }}                
                Component.onCompleted:
                {
                    if (bPageInitialized===false) fncOnComboboxCompleted();

                    console.log(SettingsDataObject.arLookupPID[SettingsDataObject.arPIDsPage1[1]].index);
                    console.log(SettingsDataObject.arLookupPID[SettingsDataObject.arPIDsPage1[1]].index.toString());

                    //currentIndex = SettingsDataObject.arLookupPID[SettingsDataObject.arPIDsPage1[1]].index;#

                    //currentIndex = 3;
                }
                onCurrentIndexChanged:
                {
                    console.log("2 changed: " + currentIndex.toString());
                }
            }

            SectionHeader
            {
                text: qsTr("Dynamic Parameters Page 2")
            }
        }
    }
}
