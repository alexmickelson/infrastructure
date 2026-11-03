import Quickshell
import QtQuick

ShellRoot {
    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }

        height: 30

        Text {
            anchors.centerIn: parent
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 11
            text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
        }

        Timer {
            id: clock
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            property date date: new Date()
            onTriggered: date = new Date()
        }
    }
}
