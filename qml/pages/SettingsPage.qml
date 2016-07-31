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
    property int iPIDPageIndex: 0;

    //Called when a combobox selection changes
    function fncOnComboboxCompleted()
    {
        bPageInitialized = true;

        //Here we collect all PID labels in one string array.
        //This is then the data model for the comboboxes.        
        //The first entry does not reference to a valid PID.
        //It is used as a placeholder if the field on a dynamic page has to be empty.
        //It refers to PID 0000.
        var arComboarray = [qsTr("Empty")];

        SettingsDataObject.arPIDarray = [{text: qsTr("Empty"), pid: "0000", index: 0}];

        var iLoopVar = 1;
        for (var i = 0; i < OBDDataObject.arrayPIDs.length; i++)
        {
            //Show only values which have a label text, because only these are showable PID's.
            //Show only PID's which are supported by the car controller.
            if (OBDDataObject.arrayPIDs[i].labeltext !== null && OBDDataObject.arrayPIDs[i].supported)
            {                
                //Add label text of PID to the combobox data array
                arComboarray.push(OBDDataObject.arrayPIDs[i].labeltext);

                //Add the other data for this PID to a helper array.
                //This array is later used to get the data for the PID based on the index.
                SettingsDataObject.arPIDarray.push({text: OBDDataObject.arrayPIDs[i].labeltext, pid: OBDDataObject.arrayPIDs[i].pid, index: iLoopVar});

                iLoopVar++;
            }            
        }

        //Fill lookup arrays. Can find entrys based on PID or INDEX as key.       
        for (var j = 0; j < SettingsDataObject.arPIDarray.length; j++)
        {
            console.log("j: " + j.toString());
            console.log("SettingsDataObject.arPIDarray[j].pid: " + SettingsDataObject.arPIDarray[j].pid);
            console.log("SettingsDataObject.arPIDarray[j].index: " + SettingsDataObject.arPIDarray[j].index);

            SettingsDataObject.arLookupPID[SettingsDataObject.arPIDarray[j].pid] = SettingsDataObject.arPIDarray[j];
            SettingsDataObject.arLookupINDEX[SettingsDataObject.arPIDarray[j].index] = SettingsDataObject.arPIDarray[j];
        }            

        arComboboxStringArray = arComboarray;
    } 

    onStatusChanged:
    {
        //Called when page is initialized
        if (status === PageStatus.Active && bPushSettingsPage)
        {
            bInitPage = true;
            bPushSettingsPage = false;

            //Generate array for the start index of the copmboboxes
            var arPIDsPage = arPIDsPagesArray[iPIDPageIndex].split(",");

            //Go through array and check if there are unsupported values.
            //Those values will be exchanged to empty fields this is PID "0000".
            for (var i = 0; i < arPIDsPage.length; i++)
            {                
                if (arPIDsPage[i] !== "0000" && OBDDataObject.arrayLookupPID[arPIDsPage[i].toLowerCase()].supported === false)
                {
                    arPIDsPage[i] = "0000";
                }
            }

            //Set start indexes of comboboxes.
            //This has to be done here, because the boxes first have to be filled with the models. That is a timing issue.
            id_CMB_page1_1.currentIndex = SettingsDataObject.arLookupPID[arPIDsPage[0]].index;
            id_CMB_page1_2.currentIndex = SettingsDataObject.arLookupPID[arPIDsPage[1]].index;
            id_CMB_page1_3.currentIndex = SettingsDataObject.arLookupPID[arPIDsPage[2]].index;
            id_CMB_page1_4.currentIndex = SettingsDataObject.arLookupPID[arPIDsPage[3]].index;
            id_CMB_page1_5.currentIndex = SettingsDataObject.arLookupPID[arPIDsPage[4]].index;
            id_CMB_page1_6.currentIndex = SettingsDataObject.arLookupPID[arPIDsPage[5]].index;

            bInitPage = false;
        }

        //Called when page is left
        if (status === PageStatus.Deactivating && !bInitPage)
        {         
            //Save values to project data when page is closed.
            //Unfortunately this is called whenever a ComboBox is opened, due to crappy QT comboboxes.

            var sPIDsPageFromPage = "";

            //Check if fields are valid and have changed. Save values.
            //Generate PID strings from comboboxe indexes
            sPIDsPageFromPage = SettingsDataObject.arLookupINDEX[id_CMB_page1_1.currentIndex].pid + "," +
                    SettingsDataObject.arLookupINDEX[id_CMB_page1_2.currentIndex].pid + "," +
                    SettingsDataObject.arLookupINDEX[id_CMB_page1_3.currentIndex].pid + "," +
                    SettingsDataObject.arLookupINDEX[id_CMB_page1_4.currentIndex].pid + "," +
                    SettingsDataObject.arLookupINDEX[id_CMB_page1_5.currentIndex].pid + "," +
                    SettingsDataObject.arLookupINDEX[id_CMB_page1_6.currentIndex].pid;

            //Check if settings changed.
            if (sPIDsPageFromPage !== arPIDsPagesArray[iPIDPageIndex])
            {
                console.log("arPIDsPagesArray[iPIDPageIndex]: " + arPIDsPagesArray[iPIDPageIndex]);
                console.log("sPIDsPageFromPage: " + sPIDsPageFromPage);

                //Save new configuration to global array variable
                //For stupid crap QML arrays, have to use a JS array as middle man...
                var arTempArray = arPIDsPagesArray;
                arTempArray[iPIDPageIndex] = sPIDsPageFromPage;
                arPIDsPagesArray = arTempArray;

                //Save new configuration to project settings
                id_ProjectSettings.vSaveProjectData("PIDsPage" + (iPIDPageIndex + 1).toString(), sPIDsPageFromPage);

                 console.log("arPIDsPagesArray[iPIDPageIndex]: " + arPIDsPagesArray[iPIDPageIndex]);
            }           
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
                text: qsTr("Dynamic Parameters Page: " + (iPIDPageIndex + 1).toString())
            }
            ComboBox
            {
                id: id_CMB_page1_1
                width: parent.width
                label: 'Parameter1:'                
                menu: ContextMenu { Repeater { model: arComboboxStringArray; MenuItem { text: modelData }}}
                Component.onCompleted: { if (bPageInitialized===false) fncOnComboboxCompleted(); }
            }
            ComboBox
            {
                id: id_CMB_page1_2
                width: parent.width
                label: 'Parameter2:'
                menu: ContextMenu { Repeater { model: arComboboxStringArray; MenuItem { text: modelData } }}
                Component.onCompleted: { if (bPageInitialized===false) fncOnComboboxCompleted(); }
            }            
            ComboBox
            {
                id: id_CMB_page1_3
                width: parent.width
                label: 'Parameter3:'
                menu: ContextMenu { Repeater { model: arComboboxStringArray; MenuItem { text: modelData } }}
                Component.onCompleted: { if (bPageInitialized===false) fncOnComboboxCompleted(); }
            }
            ComboBox
            {
                id: id_CMB_page1_4
                width: parent.width
                label: 'Parameter4:'
                menu: ContextMenu { Repeater { model: arComboboxStringArray; MenuItem { text: modelData } }}
                Component.onCompleted: { if (bPageInitialized===false) fncOnComboboxCompleted(); }
            }
            ComboBox
            {
                id: id_CMB_page1_5
                width: parent.width
                label: 'Parameter5:'
                menu: ContextMenu { Repeater { model: arComboboxStringArray; MenuItem { text: modelData } }}
                Component.onCompleted: { if (bPageInitialized===false) fncOnComboboxCompleted(); }
            }
            ComboBox
            {
                id: id_CMB_page1_6
                width: parent.width
                label: 'Parameter6:'
                menu: ContextMenu { Repeater { model: arComboboxStringArray; MenuItem { text: modelData } }}
                Component.onCompleted: { if (bPageInitialized===false) fncOnComboboxCompleted(); }
            }        
        }
    }
}
