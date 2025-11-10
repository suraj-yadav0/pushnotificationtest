#!/bin/bash
# Quick notification test - send a test notification immediately
# Usage: ./quick-test.sh [message]

APP_ID="pushnotification.surajyadav_pushnotification"
PKG_NAME="pushnotification_2esurajyadav"

# Set D-Bus session address for phablet user
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/32011/bus"

MESSAGE="${1:-Testing push notifications! 🚀}"
TITLE="${2:-Push Test}"

echo "📱 Sending notification..."
echo "Title: $TITLE"
echo "Message: $MESSAGE"
echo ""

# Use org.freedesktop.Notifications for notification panel display
gdbus call --session \
    --dest org.freedesktop.Notifications \
    --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.Notify \
    "$APP_ID" \
    0 \
    "notification" \
    "$TITLE" \
    "$MESSAGE" \
    "[]" \
    "{}" \
    5000

if [ $? -eq 0 ]; then
    echo "✅ Notification sent! Check your notification panel."
else
    echo "❌ Failed to send notification"
    echo ""
    echo "Troubleshooting:"
    echo "1. Make sure the app is installed: clickable install"
    echo "2. Launch the app at least once"
    echo "3. Check D-Bus service: gdbus introspect --session --dest com.lomiri.Postal --object-path /com/lomiri/Postal/$PKG_NAME"
fi
