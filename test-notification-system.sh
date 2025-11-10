#!/bin/bash
# Test notifications by simulating a real push through URL dispatcher

echo "=== Testing Push Notification System ==="
echo ""

# Create test push message on device
adb shell "cat > /tmp/test_push.json << 'EOF'
{
    \"message\": {
        \"loc_key\": \"MESSAGE_TEXT\",
        \"loc_args\": [\"Test User\", \"This is a test notification from the system!\"],
        \"badge\": 5,
        \"custom\": {
            \"from_id\": \"999888777\"
        }
    }
}
EOF"

echo "✅ Created test push message"
echo ""

# Trigger the URL dispatcher which should invoke our push-helper
echo "📱 Triggering notification via push system..."
adb shell "export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/32011/bus && gdbus call --session --dest com.lomiri.URLDispatcher --object-path /com/lomiri/URLDispatcher --method com.lomiri.URLDispatcher.DispatchURL 'pushnotification://test?msg=hello' 'pushnotification.surajyadav_pushnotification' 2>&1"

echo ""
echo "=== Alternative: Direct Postal Test ==="
# Also test Postal directly
adb shell "export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/32011/bus && gdbus call --session --dest com.lomiri.Postal --object-path /com/lomiri/Postal/pushnotification_2esurajyadav --method com.lomiri.Postal.Post 'pushnotification.surajyadav_pushnotification' '{\"notification\":{\"tag\":\"manual_test\",\"card\":{\"summary\":\"Manual Test\",\"body\":\"Testing Postal notification directly\",\"icon\":\"notification\",\"persist\":true,\"popup\":true}}}' 2>&1"

echo ""
echo "=== Check Badge Counter ==="
adb shell "export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/32011/bus && gdbus call --session --dest com.lomiri.Postal --object-path /com/lomiri/Postal/pushnotification_2esurajyadav --method com.lomiri.Postal.SetCounter 'pushnotification.surajyadav_pushnotification' 8 true 2>&1"

echo ""
echo "✅ Tests complete! Check your device:"
echo "   1. Look for popup notifications"
echo "   2. Check notification panel (swipe down from top)"
echo "   3. Check badge counter on app icon (should show 8)"
