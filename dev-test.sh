#!/bin/bash
# Comprehensive notification testing from development machine
# This script deploys test scripts and runs various notification tests

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Push Notification Development Testing Tool               ║"
echo "╔════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;91m'
NC='\033[0m'

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo -e "${RED}❌ No device connected via ADB${NC}"
    echo "Please connect your Ubuntu Touch device"
    exit 1
fi

echo -e "${GREEN}✓ Device connected${NC}"
echo ""

# Deploy test scripts
echo -e "${BLUE}Deploying test scripts to device...${NC}"

adb push quick-test.sh /home/phablet/ > /dev/null 2>&1
adb push test-local-notifications.py /home/phablet/ > /dev/null 2>&1
adb push send-local-notification.sh /home/phablet/ > /dev/null 2>&1

adb shell "chmod +x /home/phablet/quick-test.sh" > /dev/null 2>&1
adb shell "chmod +x /home/phablet/test-local-notifications.py" > /dev/null 2>&1
adb shell "chmod +x /home/phablet/send-local-notification.sh" > /dev/null 2>&1

echo -e "${GREEN}✓ Test scripts deployed${NC}"
echo ""

# Show menu
show_menu() {
    echo -e "${BLUE}Choose a test:${NC}"
    echo "1) Quick test - Single notification"
    echo "2) Full test suite - 5 notifications"
    echo "3) Badge counter test"
    echo "4) Custom message"
    echo "5) Spam test - 10 notifications"
    echo "6) Clear all notifications"
    echo "7) Interactive mode (on device)"
    echo "8) Deploy and install app"
    echo "9) Exit"
    echo ""
}

# Quick test
quick_test() {
    echo -e "${YELLOW}Sending quick test notification...${NC}"
    adb shell '/home/phablet/quick-test.sh "Quick test from dev machine"'
    echo ""
}

# Full test suite
full_test() {
    echo -e "${YELLOW}Running full test suite...${NC}"
    adb shell "/home/phablet/test-local-notifications.py test"
    echo ""
}

# Badge test
badge_test() {
    echo -e "${YELLOW}Testing badge counter...${NC}"
    echo "Setting badge to 1..."
    adb shell "/home/phablet/test-local-notifications.py badge 1"
    sleep 2
    echo "Setting badge to 5..."
    adb shell "/home/phablet/test-local-notifications.py badge 5"
    sleep 2
    echo "Setting badge to 10..."
    adb shell "/home/phablet/test-local-notifications.py badge 10"
    sleep 2
    echo "Clearing badge..."
    adb shell "/home/phablet/test-local-notifications.py badge 0"
    echo ""
}

# Custom message
custom_test() {
    read -p "Enter notification message: " message
    echo -e "${YELLOW}Sending custom notification...${NC}"
    adb shell "/home/phablet/quick-test.sh \"$message\""
    echo ""
}

# Spam test
spam_test() {
    echo -e "${YELLOW}Sending 10 notifications...${NC}"
    for i in {1..10}; do
        adb shell "/home/phablet/quick-test.sh \"Test notification #$i\"" 2>&1 | grep -E "(Sending|✅|✗)"
        sleep 0.5
    done
    echo ""
    echo -e "${YELLOW}Setting badge counter to 10...${NC}"
    adb shell "/home/phablet/test-local-notifications.py badge 10"
    echo ""
}

# Clear notifications
clear_test() {
    echo -e "${YELLOW}Clearing all notifications...${NC}"
    adb shell "/home/phablet/test-local-notifications.py clear"
    echo ""
}

# Interactive mode
interactive_mode() {
    echo -e "${YELLOW}Starting interactive mode on device...${NC}"
    echo "Press Ctrl+C to exit"
    echo ""
    adb shell "/home/phablet/test-local-notifications.py"
}

# Deploy app
deploy_app() {
    echo -e "${YELLOW}Building and installing app...${NC}"
    clickable build
    clickable install
    echo -e "${GREEN}✓ App deployed${NC}"
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Enter choice (1-9): " choice
    echo ""
    
    case $choice in
        1)
            quick_test
            ;;
        2)
            full_test
            ;;
        3)
            badge_test
            ;;
        4)
            custom_test
            ;;
        5)
            spam_test
            ;;
        6)
            clear_test
            ;;
        7)
            interactive_mode
            ;;
        8)
            deploy_app
            ;;
        9)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice!${NC}"
            echo ""
            ;;
    esac
done
