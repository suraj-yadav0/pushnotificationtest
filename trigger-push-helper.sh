#!/bin/bash
# Trigger push-helper on the device

echo "Creating test push message on device..."

# Create the push message file on the device
adb shell "mkdir -p /tmp/push_test && cat > /tmp/push_test/input.json << 'PUSHEOF'
{
    \"message\": {
        \"loc_key\": \"MESSAGE_TEXT\",
        \"loc_args\": [\"Test Sender\", \"This notification is from the push-helper!\"],
        \"badge\": 10,
        \"custom\": {
            \"from_id\": \"555444333\"
        }
    }
}
PUSHEOF"

echo "✅ Push message created"

# Run the push-helper directly on the device with proper environment
echo "📱 Triggering push-helper..."
adb shell "export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/32011/bus && /opt/click.ubuntu.com/pushnotification.surajyadav/1.0.0/push/push /tmp/push_test/input.json /tmp/push_test/output.json 2>&1"

echo ""
echo "📋 Push helper output:"
adb shell "cat /tmp/push_test/output.json 2>&1"

echo ""
echo "✅ Done! Check your device for:"
echo "   - Popup notification"
echo "   - Notification in panel"
echo "   - Badge showing '3'"
