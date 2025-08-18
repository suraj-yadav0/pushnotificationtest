#!/bin/bash

# Simple push notification test for Ubuntu Touch device
# Run this script ON THE DEVICE to test push notifications

echo "=== Simple Push Notification Test ==="

# Check if we're on Ubuntu Touch
if [ ! -f "/etc/system-image/channel.ini" ]; then
    echo "❌ This script should be run on an Ubuntu Touch device"
    exit 1
fi

APP_ID="pushnotification.surajyadav_pushnotification"
APP_PATH="/opt/click.ubuntu.com/pushnotification.surajyadav/current"
PUSH_HELPER="$APP_PATH/push/push"

echo "Testing push helper: $PUSH_HELPER"

if [ ! -f "$PUSH_HELPER" ]; then
    echo "❌ Push helper not found. Please install the app first."
    exit 1
fi

# Create test notification
TEST_DIR="/tmp/pushtest"
mkdir -p "$TEST_DIR"

# Test 1: Simple text message
echo "Creating test notification..."
cat > "$TEST_DIR/input.json" << 'EOF'
{
    "message": {
        "loc_key": "MESSAGE_TEXT",
        "loc_args": ["Device Test", "This is a test notification from device!"],
        "badge": 1,
        "custom": {
            "from_id": "888888888"
        }
    }
}
EOF

echo "Running push helper..."
if "$PUSH_HELPER" "$TEST_DIR/input.json" "$TEST_DIR/output.json"; then
    echo "✅ Push helper executed successfully!"
    
    if [ -f "$TEST_DIR/output.json" ]; then
        echo "📄 Generated notification:"
        cat "$TEST_DIR/output.json"
        echo ""
        
        # Try to send notification via D-Bus directly
        echo "Attempting to send notification via D-Bus..."
        
        # Extract notification data
        SUMMARY=$(jq -r '.notification.card.summary' "$TEST_DIR/output.json" 2>/dev/null || echo "Test")
        BODY=$(jq -r '.notification.card.body' "$TEST_DIR/output.json" 2>/dev/null || echo "Test message")
        
        # Send notification using notify-send (fallback)
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "$SUMMARY" "$BODY"
            echo "✅ Fallback notification sent via notify-send"
        fi
        
        # Try direct D-Bus call to Postal service
        if command -v busctl >/dev/null 2>&1; then
            echo "Available D-Bus services:"
            busctl list | grep -i postal || echo "No postal services found"
        fi
        
    else
        echo "❌ No output file generated"
    fi
else
    echo "❌ Push helper failed"
fi

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo "🔍 Checking notification logs..."
journalctl --user -f -n 10 | grep -i "notification\|postal\|push" &
JOURNAL_PID=$!

echo "Monitoring logs for 10 seconds..."
sleep 10
kill $JOURNAL_PID 2>/dev/null

echo ""
echo "✅ Test complete! Check your notification panel."
echo ""
echo "If no notifications appeared:"
echo "1. Make sure lomiri-system-settings allows notifications for your app"
echo "2. Check that Ubuntu Push Service is running: sudo service ubuntu-push-client status"
echo "3. Restart Lomiri if needed: sudo restart lomiri"
echo "4. The app needs to be properly registered with Ubuntu Push Service"
