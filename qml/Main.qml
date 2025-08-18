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
import Qt.labs.settings 1.0

// Note: Ubuntu.PushNotifications 0.1 is deprecated
// Modern Ubuntu Touch uses push-helper approach

MainView {
    id: root
    objectName: 'mainView'
    applicationName: "pushnotification.surajyadav"
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    // Settings for persistent data
    Settings {
        id: settings
        property string lastChatId: ""
        property int totalNotifications: 0
        property bool pushServiceEnabled: false
    }

    // Modern Ubuntu Touch push notification setup
    // Uses push-helper instead of deprecated PushClient
    QtObject {
        id: pushService

        property bool isInitialized: false
        property string token: ""
        property string statusMessage: "Initializing push service..."
        property bool isRegistering: false
        property int badgeCount: 0

        Component.onCompleted: {
            console.log("Modern push service initialized");
            statusMessage = "Push service ready (using push-helper approach)";
            isInitialized = true;

            // In modern Ubuntu Touch, push tokens are managed differently
            // The app registers via push-helper configuration
            checkPushHelperStatus();
        }

        function checkPushHelperStatus() {
            console.log("Checking push-helper configuration...");
            statusMessage = "Push-helper approach: Configure via push-helper.json";

            // Simulate token generation for demonstration
            Qt.callLater(function () {
                token = "demo-token-" + Math.random().toString(36).substr(2, 16);
                statusMessage = "Demo token generated (push-helper method)";
                settings.pushServiceEnabled = true;
                console.log("Demo token:", token);
            });
        }

        function register() {
            console.log("Push registration via push-helper...");
            isRegistering = true;
            statusMessage = "Registering via push-helper...";

            // In real implementation, this would configure push-helper
            // and communicate with lomiri-push-service
            Qt.callLater(function () {
                isRegistering = false;
                statusMessage = "Registration complete (push-helper method)";
                settings.pushServiceEnabled = true;
            });
        }

        function updateBadgeCount(count) {
            badgeCount = count;
            settings.totalNotifications = count;
        }
    }

    // Handle URL dispatcher events (deep links from notifications)
    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state === Qt.ApplicationActive) {
                handleAppActivation();
            }
        }
    }

    function handleAppActivation() {
        console.log("App activated - checking for deep link parameters");
        // In a real app, you would parse URL parameters here
        // Format: pushnotification://chat/123456789
        var lastChatId = settings.lastChatId;
        if (lastChatId) {
            console.log("Opening chat from notification:", lastChatId);
            openChatFromNotification(lastChatId);
        }
    }

    function openChatFromNotification(chatId) {
        console.log("Opening chat:", chatId);
        chatIdLabel.text = "Opened from notification: Chat " + chatId;
        chatIdLabel.visible = true;
        
        // Clear the stored chat ID
        settings.lastChatId = "";
        
        // Reset after 5 seconds
        clearChatTimer.start();
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
                text: pushService.statusMessage || i18n.tr('Push service status unknown')
                fontSize: "medium"
                anchors.horizontalCenter: parent.horizontalCenter
                color: {
                    if (pushService.isRegistering)
                        return "orange";
                    if (pushService.token && pushService.token.length > 0)
                        return "green";
                    return pushService.isInitialized ? "blue" : "red";
                }
            }

            Button {
                id: registerButton
                text: pushService.isRegistering ? i18n.tr('Registering...') : i18n.tr('Register Push Service')
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !(pushService.token && pushService.token.length > 0)
                enabled: !pushService.isRegistering && pushService.isInitialized

                onClicked: {
                    console.log("Manual push service registration...");
                    pushService.register();
                }
            }

            Button {
                id: pushButton
                text: i18n.tr('Send Test Notification')
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: (pushService.token && pushService.token.length > 0)

                onClicked: {
                    // For testing, we'll create a local notification
                    // In a real app, you'd send this to your server which would
                    // then send the push notification via Ubuntu Push Service
                    sendTestNotification();
                }
            }

            Label {
                id: instructionLabel
                text: {
                    var isDesktop = Qt.platform.os === "linux" && !Qt.platform.pluginName.includes("ubuntu");
                    if (isDesktop) {
                        return i18n.tr('Desktop Mode: Push notifications require an actual Ubuntu Touch device.\n\nTo test:\n1. Install on Ubuntu Touch device\n2. Run: clickable install\n3. Check device notifications');
                    } else {
                        return i18n.tr('Note: This simulates local notifications.\nReal notifications come from your server via Ubuntu Push Service.');
                    }
                }
                fontSize: "small"
                wrapMode: Text.WordWrap
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Button {
                id: copyTokenButton
                text: i18n.tr('Copy Token to Clipboard')
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: pushClient.registered && pushClient.token
                visible: pushClient.registered && pushClient.token

                onClicked: {
                    // Copy token to clipboard for server integration testing
                    console.log("Token copied: " + pushClient.token);
                    // Note: Clipboard functionality would need additional implementation
                    helloLabel.text = i18n.tr('Token copied!');
                    resetTimer.start();
                }
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
                        text: i18n.tr('Service: ') + (pushService.isInitialized ? 'Ready' : 'Not Ready')
                        fontSize: "small"
                    }

                    Label {
                        text: i18n.tr('Registered: ') + ((pushService.token && pushService.token.length > 0) ? 'Yes' : 'No')
                        fontSize: "small"
                    }

                    Label {
                        text: i18n.tr('Token: ') + (pushService.token || 'Not available')
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
        console.log("=== SENDING TEST NOTIFICATION ===");
        console.log("Push service token:", pushService.token || "No token available");
        console.log("Token length:", pushService.token ? pushService.token.length : 0);
        console.log("Service initialized:", pushService.isInitialized);

        if (pushService.token && pushService.token.length > 0) {
            console.log("✓ Push service is ready with token");
            helloLabel.text = i18n.tr('Test notification sent!\nToken: ') + pushService.token.substring(0, 20) + "...";
        } else {
            console.log("✗ Push service not ready - cannot send notification");
            helloLabel.text = i18n.tr('Cannot send notification:\nPush service not ready');
        }

        // Show a visual notification simulation
        testNotificationRect.visible = true;
        testNotificationTimer.start();

        // Reset the text after some time
        resetTimer.start();
    }

    // Visual notification simulation
    Rectangle {
        id: testNotificationRect
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: units.gu(8)
        color: "#2196F3"
        visible: false
        z: 1000

        Label {
            anchors.centerIn: parent
            text: i18n.tr('🔔 Simulated Push Notification\nThis would be a real notification from your server')
            color: "white"
            fontSize: "medium"
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Timer {
        id: testNotificationTimer
        interval: 3000
        repeat: false
        onTriggered: {
            testNotificationRect.visible = false;
        }
    }

    Timer {
        id: resetTimer
        interval: 3000
        repeat: false
        onTriggered: {
            helloLabel.text = i18n.tr('Hello World!');
        }
    }
}
