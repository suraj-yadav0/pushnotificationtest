#!/bin/bash

# Comprehensive Push Notification Debugging Script for Ubuntu Touch
# This script helps diagnose why push notifications aren't appearing

echo "=== Ubuntu Touch Push Notification Debug ==="
echo "Date: $(date)"
echo ""

# Check if we're running on Ubuntu Touch
echo "1. System Information:"
echo "   OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "   Kernel: $(uname -r)"
echo "   Architecture: $(uname -m)"
echo ""

# Check if the app is installed
echo "2. App Installation Check:"
APP_PATH="/opt/click.ubuntu.com/pushnotification.surajyadav"
if [ -d "$APP_PATH" ]; then
    echo "   ✓ App is installed at: $APP_PATH"
    echo "   Version: $(ls $APP_PATH/ | head -1)"
    
    # Check push helper files
    PUSH_HELPER="$APP_PATH/current/push/push"
    PUSH_CONFIG="$APP_PATH/current/push/push-helper.json"
    PUSH_APPARMOR="$APP_PATH/current/push/push-apparmor.json"
    
    echo ""
    echo "3. Push Helper Files:"
    if [ -f "$PUSH_HELPER" ]; then
        echo "   ✓ Push helper binary exists: $PUSH_HELPER"
        echo "     Size: $(stat -c%s "$PUSH_HELPER") bytes"
        echo "     Permissions: $(stat -c%A "$PUSH_HELPER")"
    else
        echo "   ✗ Push helper binary missing: $PUSH_HELPER"
    fi
    
    if [ -f "$PUSH_CONFIG" ]; then
        echo "   ✓ Push helper config exists: $PUSH_CONFIG"
        echo "     Content: $(cat "$PUSH_CONFIG")"
    else
        echo "   ✗ Push helper config missing: $PUSH_CONFIG"
    fi
    
    if [ -f "$PUSH_APPARMOR" ]; then
        echo "   ✓ Push AppArmor policy exists: $PUSH_APPARMOR"
        echo "     Content: $(cat "$PUSH_APPARMOR")"
    else
        echo "   ✗ Push AppArmor policy missing: $PUSH_APPARMOR"
    fi
else
    echo "   ✗ App not found at: $APP_PATH"
    echo "   Try: clickable install"
fi

echo ""
echo "4. Manifest Check:"
MANIFEST="$APP_PATH/current/manifest.json"
if [ -f "$MANIFEST" ]; then
    echo "   ✓ Manifest exists"
    echo "   Push hook configuration:"
    grep -A 10 '"push"' "$MANIFEST" || echo "   ✗ No push hook found in manifest"
else
    echo "   ✗ Manifest not found"
fi

echo ""
echo "5. Push Service Status:"
# Check if push service is running
if pgrep -f "ubuntu-push" > /dev/null; then
    echo "   ✓ Ubuntu Push Service is running"
    echo "   Processes:"
    pgrep -f "ubuntu-push" | while read pid; do
        echo "     PID $pid: $(ps -p $pid -o comm= 2>/dev/null || echo 'unknown')"
    done
else
    echo "   ✗ Ubuntu Push Service not running"
    echo "   Try: sudo service ubuntu-push-client restart"
fi

echo ""
echo "6. Postal Service Status:"
# Check if postal service is running
if pgrep -f "lomiri.*postal\|ubuntu.*postal" > /dev/null; then
    echo "   ✓ Postal Service is running"
else
    echo "   ✗ Postal Service not running"
    echo "   Try: sudo service lomiri restart"
fi

echo ""
echo "7. D-Bus Services:"
# Check D-Bus services
echo "   Available D-Bus services (postal related):"
busctl list 2>/dev/null | grep -i postal || echo "   No postal services found"

echo ""
echo "8. App Permissions:"
# Check AppArmor profile
PROFILE_NAME="pushnotification.surajyadav_pushnotification"
if aa-status 2>/dev/null | grep -q "$PROFILE_NAME"; then
    echo "   ✓ AppArmor profile loaded: $PROFILE_NAME"
    # Check if profile allows push notifications
    echo "   Profile details:"
    aa-status 2>/dev/null | grep "$PROFILE_NAME" | head -5
else
    echo "   ✗ AppArmor profile not found: $PROFILE_NAME"
fi

echo ""
echo "9. Recent App Logs:"
echo "   Last 20 lines from app logs:"
journalctl --user -u lomiri-app-launch* | grep pushnotification | tail -20 || echo "   No recent app logs found"

echo ""
echo "10. Manual Push Helper Test:"
echo "    Creating test notification..."

# Create test input file
TEST_DIR="/tmp/push-test-$$"
mkdir -p "$TEST_DIR"
INPUT_FILE="$TEST_DIR/input.json"
OUTPUT_FILE="$TEST_DIR/output.json"

cat > "$INPUT_FILE" << 'EOF'
{
    "message": {
        "loc_key": "MESSAGE_TEXT",
        "loc_args": ["Test Sender", "Debug test message from push helper"],
        "badge": 1,
        "custom": {
            "from_id": "999999999"
        }
    }
}
EOF

if [ -f "$PUSH_HELPER" ]; then
    echo "    Running push helper manually..."
    if timeout 10s "$PUSH_HELPER" "$INPUT_FILE" "$OUTPUT_FILE" 2>&1; then
        echo "    ✓ Push helper executed successfully"
        if [ -f "$OUTPUT_FILE" ]; then
            echo "    Output notification:"
            cat "$OUTPUT_FILE" | jq . 2>/dev/null || cat "$OUTPUT_FILE"
        else
            echo "    ✗ No output file generated"
        fi
    else
        echo "    ✗ Push helper failed or timed out"
    fi
else
    echo "    ✗ Cannot test - push helper not found"
fi

# Cleanup
rm -rf "$TEST_DIR"

echo ""
echo "11. Notification Database:"
DB_PATH="$HOME/.local/share/pushnotification.surajyadav/auxdb/auxdb.sqlite"
if [ -f "$DB_PATH" ]; then
    echo "    ✓ Notification database exists: $DB_PATH"
    echo "    Database contents:"
    sqlite3 "$DB_PATH" "SELECT 'Chat ID', 'Avatar Path', 'Unread Count';" 2>/dev/null || echo "    Headers"
    sqlite3 "$DB_PATH" "SELECT id, path, unread_messages FROM chatlist_map;" 2>/dev/null || echo "    No data or error reading database"
    echo "    Total unread: $(sqlite3 "$DB_PATH" "SELECT SUM(unread_messages) FROM chatlist_map;" 2>/dev/null || echo "Error")"
else
    echo "    ✗ Notification database not found: $DB_PATH"
fi

echo ""
echo "=== Troubleshooting Recommendations ==="
echo ""

# Provide specific recommendations based on findings
if [ ! -f "$PUSH_HELPER" ]; then
    echo "❌ CRITICAL: Push helper binary is missing"
    echo "   Solution: Rebuild and reinstall the app:"
    echo "   $ clickable build"
    echo "   $ clickable install"
    echo ""
fi

if [ ! -f "$PUSH_CONFIG" ]; then
    echo "❌ CRITICAL: Push helper configuration is missing"
    echo "   Solution: Check push/push-helper.json in your source code"
    echo ""
fi

if ! pgrep -f "ubuntu-push" > /dev/null; then
    echo "⚠️  WARNING: Ubuntu Push Service is not running"
    echo "   Solution: Restart the push service:"
    echo "   $ sudo service ubuntu-push-client restart"
    echo ""
fi

if ! busctl list 2>/dev/null | grep -q postal; then
    echo "⚠️  WARNING: Postal service not accessible via D-Bus"
    echo "   Solution: Restart Lomiri:"
    echo "   $ sudo service lomiri restart"
    echo ""
fi

echo "🔧 NEXT STEPS:"
echo "1. If push helper is missing, rebuild and reinstall the app"
echo "2. Test notifications from external push service (not from within the app)"
echo "3. Check that your server is sending notifications to Ubuntu Push Service"
echo "4. Verify the app is properly registered for push notifications"
echo ""
echo "📱 To test real push notifications:"
echo "1. Get a real push token by registering with Ubuntu Push Service"
echo "2. Use the server-example.py script to send test notifications"
echo "3. Notifications should appear in the system notification panel"
echo ""
echo "=== Debug Complete ==="
