/*
 * Copyright (C) 2025  Suraj Yadav
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * pushnotification is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.PushNotifications 0.1

MainView {
    id: root
    objectName: 'mainView'
    applicationName: "pushnotification.surajyadav"
    automaticOrientation: true
    
    width: units.gu(45)
    height: units.gu(75)

    PushClient {
        id: pushClient
        Component.onCompleted: {
            // Register for push notifications
            if (!pushClient.registered) {
                pushClient.register()
            }
        }
        
        onRegistered: {
            console.log("Push client registered successfully")
        }
        
        onRegistrationFailed: {
            console.log("Push client registration failed: " + reason)
        }
        
        onNotificationReceived: {
            console.log("Notification received: " + message)
        }
    }

    Page {
        id: page
        header: PageHeader {
            id: pageHeader
            title: i18n.tr('Push Notification Demo')
        }

        Column {
            id: mainColumn
            anchors {
                top: pageHeader.bottom
                left: parent.left
                right: parent.right
                margins: units.gu(2)
            }
            spacing: units.gu(2)

            Label {
                id: helloLabel
                text: i18n.tr('Hello World!')
                fontSize: "x-large"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                id: statusLabel
                text: pushClient.registered ? 
                      i18n.tr('Push notifications enabled') : 
                      i18n.tr('Push notifications not registered')
                fontSize: "medium"
                anchors.horizontalCenter: parent.horizontalCenter
                color: pushClient.registered ? "green" : "red"
            }

            Button {
                id: pushButton
                text: i18n.tr('Send Test Notification')
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: pushClient.registered
                
                onClicked: {
                    // For testing, we'll create a local notification
                    // In a real app, you'd send this to your server which would
                    // then send the push notification via Ubuntu Push Service
                    sendTestNotification()
                }
            }

            Label {
                id: instructionLabel
                text: i18n.tr('Note: This is a local test notification.\nIn production, notifications would come from a server.')
                fontSize: "small"
                wrapMode: Text.WordWrap
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Rectangle {
                id: infoBox
                width: parent.width
                height: units.gu(15)
                color: "#f0f0f0"
                border.color: "#cccccc"
                border.width: 1
                radius: units.gu(1)

                Column {
                    anchors.margins: units.gu(1)
                    anchors.fill: parent
                    spacing: units.gu(0.5)

                    Label {
                        text: i18n.tr('Registration Info:')
                        fontSize: "medium"
                        font.bold: true
                    }

                    Label {
                        text: i18n.tr('Registered: ') + (pushClient.registered ? 'Yes' : 'No')
                        fontSize: "small"
                    }

                    Label {
                        text: i18n.tr('Token: ') + (pushClient.token || 'Not available')
                        fontSize: "small"
                        wrapMode: Text.WrapAnywhere
                        width: parent.width - units.gu(2)
                    }
                }
            }
        }
    }

    // Function to simulate a test notification
    function sendTestNotification() {
        console.log("Sending test notification...")
        
        // In a real application, you would:
        // 1. Send the push token to your server
        // 2. Your server would make a request to Ubuntu Push Service
        // 3. Ubuntu Push Service would deliver the notification to the device
        
        // For demonstration, we'll just show an in-app message
        helloLabel.text = i18n.tr('Test notification sent!')
        
        // Reset the text after 3 seconds
        resetTimer.start()
    }

    Timer {
        id: resetTimer
        interval: 3000
        repeat: false
        onTriggered: {
            helloLabel.text = i18n.tr('Hello World!')
        }
    }
}