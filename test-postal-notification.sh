#!/bin/bash
# Test script to demonstrate system notifications using the Postal service
# This shows how notifications appear in the Lomiri notification panel

APP_ID="pushnotification.surajyadav_pushnotification"
PKG_NAME="pushnotification_2esurajyadav"

# Set D-Bus session address for phablet user
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/32011/bus"

echo "Testing Lomiri Postal Service notifications..."
echo "App ID: $APP_ID"
echo "Package: $PKG_NAME"
echo

# Test notification message in the correct format
NOTIFICATION_JSON='{
    "message": "Test notification from Lomiri Postal Service",
    "notification": {
        "card": {
            "summary": "Test Notification",
            "body": "This notification appears in the system panel!",
            "popup": true,
            "persist": true
        },
        "sound": true,
        "vibrate": true,
        "tag": "test-notification"
    }
}'

echo "Sending notification via gdbus..."
echo "Command: gdbus call --session --dest com.lomiri.Postal --object-path /com/lomiri/Postal/$PKG_NAME --method com.lomiri.Postal.Post $APP_ID '$NOTIFICATION_JSON'"

gdbus call --session \
    --dest com.lomiri.Postal \
    --object-path "/com/lomiri/Postal/$PKG_NAME" \
    --method com.lomiri.Postal.Post \
    "$APP_ID" \
    "$NOTIFICATION_JSON"

echo
echo "If successful, you should see a notification in the Lomiri notification panel."
echo "The notification will have the title 'Test Notification' and body 'This notification appears in the system panel!'"