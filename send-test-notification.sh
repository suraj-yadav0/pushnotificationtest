#!/bin/bash
# Simple notification tester - run from development machine
# Usage: ./send-test-notification.sh [message]

MESSAGE="${1:-Test notification from development machine}"

echo "📱 Deploying and sending notification..."
echo "Message: $MESSAGE"
echo ""

# Deploy scripts
adb push quick-test.sh /home/phablet/ > /dev/null 2>&1
adb shell "chmod +x /home/phablet/quick-test.sh" > /dev/null 2>&1

# Send notification
adb shell "/home/phablet/quick-test.sh \"$MESSAGE\""

echo ""
echo "✅ Done! Check your device notification panel."
