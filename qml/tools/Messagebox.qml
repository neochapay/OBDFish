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
