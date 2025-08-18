#!/bin/bash

# Simple notification test script
echo "=== Testing Simple Notifications ==="

# Test 1: Basic notify-send
echo "1. Testing notify-send..."
if command -v notify-send >/dev/null 2>&1; then
    notify-send "Push Notification Test" "✅ This is a test notification from your app!" \
        --icon=info \
        --urgency=normal \
        --expire-time=5000 \
        --app-name="Push Notification Test"
    echo "   ✓ notify-send executed"
else
    echo "   ❌ notify-send not available"
fi

# Test 2: Write to journal for verification
echo "2. Logging notification..."
echo "$(date): Test notification sent - Push Notification Test" >> /tmp/notification-test.log
echo "   ✓ Logged to /tmp/notification-test.log"

# Test 3: Try different notification methods
echo "3. Testing additional methods..."

# DBus notification (if available)
if command -v gdbus >/dev/null 2>&1; then
    gdbus call --session \
        --dest=org.freedesktop.Notifications \
        --object-path=/org/freedesktop/Notifications \
        --method=org.freedesktop.Notifications.Notify \
        "Push Notification Test" 0 "info" \
        "Test Notification" "This is a test notification via DBus!" \
        '[]' '{}' 5000 2>/dev/null && echo "   ✓ DBus notification sent" || echo "   ❌ DBus failed"
fi

echo "=== Test Complete ==="
echo "Check your notification panel for the test notification!"
