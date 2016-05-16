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

BackgroundItem
{
    id: messagebox
    z: 20
    visible: messageboxVisibility.running
    height: Theme.itemSizeSmall + Theme.paddingSmall + messageboxText.height
    anchors.centerIn: parent
    width: parent.width
    onClicked: messageboxVisibility.stop()

    Rectangle
    {
        height: Theme.paddingSmall
        width: parent.width
        color: Theme.highlightBackgroundColor
    }

    Rectangle
    {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
    }

    function showMessage(message, delay)
    {
        messageboxText.text = message
        messageboxVisibility.interval = (delay>0) ? delay : 3000
        messageboxVisibility.restart()
    }

    Label
    {
        id: messageboxText
        width: parent.width
        wrapMode: Text.WordWrap
        color: Theme.primaryColor
        text: ""
        anchors.centerIn: parent
    }

    Timer
    {
        id: messageboxVisibility
        interval: 3000
    }
}
