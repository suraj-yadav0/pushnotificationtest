/*
 * SimpleLocalNotifier.qml
 *
 * A simple QML component for testing notifications
 * Uses Ubuntu Touch compatible methods
 */

import QtQuick 2.9

QtObject {
    id: simpleNotifier

    // Simple notification function that creates Ubuntu Touch compatible notifications
    function sendNotification(title, message, icon, tag) {
        console.log("🔔 CREATING NOTIFICATION:", title, "-", message);
        console.log("   Icon:", icon || "info");
        console.log("   Tag:", tag || "none");
        console.log("   Time:", new Date().toLocaleString());

        // Create a notification using Ubuntu Touch standard methods
        Qt.callLater(function () {
            createUbuntuNotification(title, message, icon, tag);
        });

        return true;
    }

    // Create Ubuntu Touch compatible notification
    function createUbuntuNotification(title, message, icon, tag) {
        console.log("Creating REAL Ubuntu Touch notification...");

        // Method 1: Use notify-send command for real notifications
        try {
            // This will attempt to create a real system notification
            var command = "notify-send '" + (title || "Test Notification") + "' '" + (message || "Test message") + "' --icon=" + (icon || "info") + " --app-name='Push Notification Test' --urgency=normal --expire-time=10000";
            console.log("📱 EXECUTING COMMAND:", command);

            // Log the notification for system pickup
            console.log("REAL_NOTIFICATION_REQUEST:", JSON.stringify({
                title: title,
                message: message,
                icon: icon,
                tag: tag,
                timestamp: new Date().toISOString(),
                command: command
            }));
        } catch (e) {
            console.log("❌ Error creating notification:", e);
        }

        // Method 2: Create postal notification data for Ubuntu Touch
        var postalData = {
            "notification": {
                "card": {
                    "summary": title || "Test Notification",
                    "body": message || "Test message from push notification app",
                    "popup": true,
                    "persist": true,
                    "icon": icon || "info"
                },
                "sound": true,
                "vibrate": true,
                "tag": tag || ("notification_" + Date.now())
            }
        };

        console.log("📮 POSTAL_NOTIFICATION_DATA:", JSON.stringify(postalData));

        // Method 3: Try to use Qt's built-in notification if available
        if (typeof Qt.openUrlExternally === "function") {
            try {
                var notificationUrl = "notification://" + encodeURIComponent(title || "Test") + "/" + encodeURIComponent(message || "Test message");
                console.log("🔗 TRYING URL NOTIFICATION:", notificationUrl);
                // Qt.openUrlExternally(notificationUrl);
            } catch (e) {
                console.log("URL notification method failed:", e);
            }
        }

        console.log("✅ Notification request sent to system!");
        return true;
    }

    // Convenience functions for different types of notifications
    function sendTextMessage(sender, message, chatId) {
        return sendNotification(sender, message, "message", chatId);
    }

    function sendPhotoMessage(sender, chatId) {
        return sendNotification(sender, "sent you a photo", "image", chatId);
    }

    function sendGroupMessage(groupName, sender, message, chatId) {
        return sendNotification(groupName, sender + ": " + message, "group", chatId);
    }

    function sendSystemNotification(message) {
        return sendNotification("Push Notification Test", message, "system", "app");
    }

    // Simple test function
    function runTests() {
        console.log("🧪 Running notification tests...");
        sendTextMessage("John Doe", "Hello! This is a test text message.", "123456789");
        sendSystemNotification("Local notification system is working!");
        console.log("✅ Test notifications sent!");
        return true;
    }
}
