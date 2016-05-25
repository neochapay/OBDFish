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
    property bool bPushSettingsPage: true
    property bool bInitPage: true
    property variant arComboboxStringArray : []
    property variant arPIDStringArray : []
    property variant arLookupPIDs: []

    function fncTester()
    {
        console.log("Tester");
    }

    onStatusChanged:
    {
        if (status === PageStatus.Active && bPushSettingsPage)
        {
            bInitPage = true;
            bPushSettingsPage = false;

            //Here we collect all PID labels in one string array.
            //This is then the data model for the comboboxes.
            var arComboarray = ["None"];
            var arPIDarray = [{text: "None", pid: "0000", index: 0}];       //Stupid qml crap. Need this additional array to get PID of selected combobox index.
            for (var i = 0; i < OBDDataObject.arrayPIDs.length; i++)
            {
                if (OBDDataObject.arrayPIDs[i].labeltext !== null)
                {
                    arComboarray.push(OBDDataObject.arrayPIDs[i].labeltext);
                    arPIDarray.push({text: OBDDataObject.arrayPIDs[i].labeltext, pid: OBDDataObject.arrayPIDs[i].pid, index: i});
                }
            }

            var arrayLookupPID = {};
            for (var j = 0; j < arPIDarray.length; j++)
            {
                arrayLookupPID[arPIDarray[j].pid] = arPIDarray[j];
            }



            //sPIDsPage1: "0104,0105,010c,010d,010e,0111";
            //Set saved values to comboboxes, separate strings by decimal point
            var arPIDsPage1 = sPIDsPage1.split(",");
            //id_CMB_page1_1.currentIndex = arrayLookupPID[arPIDsPage1[0]].index;
            //id_CMB_page1_2.currentIndex = arrayLookupPID[arPIDsPage1[1]].index;

            sComboboxStringArray = arComboarray;
            sPIDStringArray = arPIDarray;
            arLookupPIDs = arrayLookupPID;
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
                menu: ContextMenu { Repeater { model: sComboboxStringArray; MenuItem { text: modelData }}}
                Component.onCompleted:
                {
                    var arPIDsPage1 = sPIDsPage1.split(",");
                    currentIndex = arLookupPIDs[arPIDsPage1[0]].index;
                }
                onCurrentIndexChanged:
                {
                    fncTester(1);
                }
            }

            ComboBox
            {
                id: id_CMB_page1_2
                width: parent.width
                label: 'Parameter2:'
                currentIndex: 0
                menu: ContextMenu { Repeater { model: sComboboxStringArray; MenuItem { text: modelData } }}
                Component.onCompleted:
                {
                    var arPIDsPage1 = sPIDsPage1.split(",");
                    currentIndex = arLookupPIDs[arPIDsPage1[1]].index;
                }
                onCurrentIndexChanged:
                {
                    fncTester(2);
                }
            }





            SectionHeader
            {
                text: qsTr("Dynamic Parameters Page 2")
            }



        }
    }
}
