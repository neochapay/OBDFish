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

    SilicaFlickable
    {
        anchors.fill: parent
        contentHeight: id_Column_Main.height

        VerticalScrollDecorator {}

        Column
        {
            id: id_Column_Main

            spacing: Theme.paddingLarge
            width: parent.width

            PageHeader { title: qsTr("Settings") }

            ComboBox
            {
                id: selector

                width: parent.width
                label: 'Parameter1:'
                //currentIndex: -1
                currentIndex: 0

                menu: ContextMenu
                {
                    Repeater
                    {
                        model: [ 'Fruit', 'Vegetable' ]     //TODO: Generate string from PID table

                        MenuItem
                        {
                            text: modelData
                        }
                    }
                }
            }

        /*
            ComboBox
            {
                label: qsTr("Map source", "Settings option name")
                menu: ContextMenu
                {
                    Repeater
                    {
                        width: parent.width
                        model: mapSourceModel
                        delegate: MenuItem { text: model.name }
                    }
                }
                onCurrentItemChanged:
                {
                    if (pageStack.currentPage.objectName === "settings" || pageStack.currentPage.objectName === "")
                    {
                        settings.mapSource = mapSourceModel.get(currentIndex).value
                    }
                }
                Component.onCompleted:
                {
                    _updating = false
                    for (var i = 0; i < mapSourceModel.count; i++)
                    {
                        if (mapSourceModel.get(i).value == settings.mapSource)
                        {
                            currentIndex = i
                            break
                        }
                    }
                }
            }*/

            ComboBox
            {
                width: parent.width
                label: "Parameter 1"
                currentIndex: 1

                menu: ContextMenu
                {
                    MenuItem { text: "Up" }
                    MenuItem { text: "Down" }
                    MenuItem { text: "Left" }
                    MenuItem { text: "Right" }
                }
                description: "This combobox comes with an extra description."
            }
        }
    }
}
