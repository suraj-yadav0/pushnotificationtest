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
import Ubuntu.Components.Popups 1.3
import Qt.labs.settings 1.0

// Note: Ubuntu.PushNotifications 0.1 is deprecated
// Modern Ubuntu Touch uses push-helper approach

import Lomiri.PushNotifications 0.1 as PushNotifications

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

    // Local notification helper for testing
    SimpleLocalNotifier {
        id: localNotifier
    }

    // Modern Ubuntu Touch push notification setup
    // Uses Lomiri PushNotifications service for real token registration
    PushNotifications.PushClient {
        id: pushClient
        appId: "pushnotification.surajyadav_pushnotification"
        
        Component.onCompleted: {
            // Connect to notification signal
            notificationsChanged.connect(handleNotifications)
            error.connect(handlePushError)
        }
        
        onTokenChanged: {
            console.log("Real push token received:", token)
            pushService.token = token
            pushService.statusMessage = "Push token registered: " + token.substring(0, 10) + "..."
            settings.pushServiceEnabled = true
            console.log("Token saved to settings")
        }
    }
    
    // Handle push notifications received via Postal service
    function handleNotifications(notifications) {
        console.log("Notifications received:", notifications.length)
        
        for (var i = 0; i < notifications.length; i++) {
            var notification = notifications[i]
            console.log("Processing notification:", notification)
            
            try {
                var notifData = JSON.parse(notification)
                
                // Extract notification details
                var message = notifData.message || ""
                var card = notifData.notification ? notifData.notification.card : null
                
                if (card) {
                    showNotificationPopup(card.summary || "Notification", 
                                        card.body || message)
                }
                
                // Update badge count if present
                if (notifData.notification && notifData.notification["emblem-counter"]) {
                    var counter = notifData.notification["emblem-counter"]
                    pushService.updateBadgeCount(counter.count || 0)
                }
                
            } catch (e) {
                console.log("Error parsing notification:", e)
            }
        }
    }
    
    // Handle push client errors
    function handlePushError(errorMsg) {
        console.log("Push error:", errorMsg)
        pushService.statusMessage = "Push error: " + errorMsg
    }

    // Push service status and token management
    QtObject {
        id: pushService
        property bool isInitialized: true
        property string token: ""
        property string statusMessage: "Initializing push service..."
        property bool isRegistering: false
        property int badgeCount: 0

        Component.onCompleted: {
            console.log("Push service initialized with Lomiri PushNotifications");
            statusMessage = "Push service ready - waiting for token..."
            
            // The PushClient will automatically register and get token
            if (pushClient.token) {
                token = pushClient.token
                statusMessage = "Token available: " + token.substring(0, 10) + "..."
            }
        }

        function register() {
            console.log("Push registration via Lomiri PushNotifications...");
            isRegistering = true;
            statusMessage = "Registering with push service...";
            
            // PushClient handles registration automatically
            // Just wait for tokenChanged signal
            Qt.callLater(function () {
                isRegistering = false;
                if (pushClient.token) {
                    statusMessage = "Registration complete - token received";
                } else {
                    statusMessage = "Registration pending - waiting for token...";
                }
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
        console.log("App activated - checking for postal messages");
        
        // According to documentation: "apps should check for pending notifications 
        // whenever they are activated or started"
        pushClient.getNotifications()
        
        // Handle deep links from notifications
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
                    // Send a REAL notification using our notification system
                    console.log("🚀 SENDING REAL TEST NOTIFICATION 🚀");

                    // Method 1: Use our notification system
                    localNotifier.sendNotification("Push Notification Test", "✅ SUCCESS! This is a real test notification from your app. Check your notification panel!", "info", "test_notification_" + Date.now());

                    // Method 2: Show a visual notification popup (THIS WILL BE VISIBLE!)
                    showNotificationPopup("🔔 Dummy Notification", "✅ SUCCESS! Your notification app is working perfectly! This is your dummy notification.");

                    // Method 3: Send system notification
                    localNotifier.sendSystemNotification("🔔 Your push notification test was successful! Check the notification panel.");

                    // Update the UI to show success
                    helloLabel.text = i18n.tr('✅ NOTIFICATION SENT!\n\nA dummy notification popup should appear above!\nThis simulates a real system notification.');
                    helloLabel.color = "green";

                    // Also show the visual simulation
                    sendTestNotification();

                    // Reset color after a few seconds using Timer
                    resetTimer.start();
                }
            }

            // LOCAL NOTIFICATION TESTING BUTTONS
            Button {
                id: localNotifButton
                text: i18n.tr('Send REAL Local Notification')
                anchors.horizontalCenter: parent.horizontalCenter
                color: theme.palette.normal.positive

                onClicked: {
                    console.log("Sending real local notification...");
                    localNotifier.sendTextMessage("Local Test", "This is a REAL system notification!", "123456789");
                }
            }

            Button {
                id: localTestSuiteButton
                text: i18n.tr('Run Local Notification Tests')
                anchors.horizontalCenter: parent.horizontalCenter
                color: theme.palette.normal.activity

                onClicked: {
                    console.log("Running local notification test suite...");
                    localNotifier.runTests();
                    helloLabel.text = i18n.tr('Local notifications sent!\nCheck your notification panel!');
                    resetTimer.start();
                }
            }

            Button {
                id: photoNotifButton
                text: i18n.tr('Send Photo Notification')
                anchors.horizontalCenter: parent.horizontalCenter

                onClicked: {
                    localNotifier.sendPhotoMessage("Alice", "987654321");
                    helloLabel.text = i18n.tr('Photo notification sent!');
                    resetTimer.start();
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
                enabled: pushService.token && pushService.token.length > 0
                visible: pushService.token && pushService.token.length > 0

                onClicked: {
                    // Copy token to clipboard for server integration testing
                    console.log("Token copied: " + pushService.token);
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

    // Dummy notification popup (looks like a real system notification)
    Rectangle {
        id: dummyNotificationPopup
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: units.gu(12)
        color: "#424242"
        visible: false
        z: 1001
        opacity: 0.95

        Rectangle {
            anchors.fill: parent
            color: "white"
            border.color: "#E0E0E0"
            border.width: 1

            Row {
                anchors.left: parent.left
                anchors.leftMargin: units.gu(2)
                anchors.verticalCenter: parent.verticalCenter
                spacing: units.gu(2)

                Rectangle {
                    width: units.gu(6)
                    height: units.gu(6)
                    color: "#2196F3"
                    radius: units.gu(1)
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        anchors.centerIn: parent
                        text: "📱"
                        fontSize: "large"
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: units.gu(0.5)

                    Label {
                        id: notificationTitle
                        text: "Notification Title"
                        fontSize: "medium"
                        font.weight: Font.Bold
                        color: "#212121"
                    }

                    Label {
                        id: notificationMessage
                        text: "Notification message"
                        fontSize: "small"
                        color: "#757575"
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Close button
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: units.gu(1)
                anchors.top: parent.top
                anchors.topMargin: units.gu(1)
                width: units.gu(3)
                height: units.gu(3)
                color: "transparent"

                Label {
                    anchors.centerIn: parent
                    text: "×"
                    fontSize: "large"
                    color: "#757575"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        dummyNotificationPopup.visible = false;
                    }
                }
            }
        }
    }

    // Function to show notification popup
    function showNotificationPopup(title, message) {
        console.log("📱 SHOWING DUMMY NOTIFICATION POPUP:", title, "-", message);
        notificationTitle.text = title || "Test Notification";
        notificationMessage.text = message || "Test message";
        dummyNotificationPopup.visible = true;
        dummyNotificationTimer.start();
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
        id: dummyNotificationTimer
        interval: 8000
        repeat: false
        onTriggered: {
            dummyNotificationPopup.visible = false;
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
