#!/bin/bash
# Local notification testing script for development
# Run this on your Ubuntu Touch device to send test notifications

APP_ID="pushnotification.surajyadav_pushnotification"
PKG_NAME="pushnotification_2esurajyadav"

# Set D-Bus session address for phablet user
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/32011/bus"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Push Notification Local Testing Tool     ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo ""

# Function to send notification
send_notification() {
    local title="$1"
    local body="$2"
    local tag="${3:-test-$(date +%s)}"
    local icon="${4:-notification}"
    
    echo -e "${YELLOW}Sending: $title${NC}"
    echo -e "Message: $body"
    echo ""
    
    # Use org.freedesktop.Notifications for notification panel display
    gdbus call --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify \
        "$APP_ID" \
        0 \
        "$icon" \
        "$title" \
        "$body" \
        "[]" \
        "{}" \
        5000 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Notification sent successfully!${NC}"
    else
        echo -e "❌ Failed to send notification"
    fi
    echo ""
}

# Function to set badge counter
set_badge() {
    local count=$1
    local visible="true"
    
    if [ "$count" -eq 0 ]; then
        visible="false"
    fi
    
    echo -e "${YELLOW}Setting badge counter to: $count${NC}"
    
    gdbus call --session \
        --dest com.lomiri.Postal \
        --object-path "/com/lomiri/Postal/$PKG_NAME" \
        --method com.lomiri.Postal.SetCounter \
        "$APP_ID" "$count" "$visible" 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Badge counter updated!${NC}"
    else
        echo -e "❌ Failed to update badge"
    fi
    echo ""
}

# Function to clear notifications
clear_notifications() {
    local tag="${1:-}"
    
    echo -e "${YELLOW}Clearing notifications...${NC}"
    
    if [ -z "$tag" ]; then
        gdbus call --session \
            --dest com.lomiri.Postal \
            --object-path "/com/lomiri/Postal/$PKG_NAME" \
            --method com.lomiri.Postal.ClearPersistent \
            "$APP_ID" "" 2>&1
    else
        gdbus call --session \
            --dest com.lomiri.Postal \
            --object-path "/com/lomiri/Postal/$PKG_NAME" \
            --method com.lomiri.Postal.ClearPersistent \
            "$APP_ID" "$tag" 2>&1
    fi
    
    echo -e "${GREEN}✓ Notifications cleared!${NC}"
    echo ""
}

# Main menu
if [ "$#" -eq 0 ]; then
    echo "Choose a test:"
    echo "1) Simple notification"
    echo "2) Message notification"
    echo "3) Photo notification"
    echo "4) Group message"
    echo "5) Set badge counter"
    echo "6) Clear notifications"
    echo "7) Run all tests"
    echo "8) Custom notification"
    echo ""
    read -p "Enter choice (1-8): " choice
else
    choice="$1"
fi

case "$choice" in
    1)
        send_notification "Test Notification" "This is a simple test notification!" "test-simple"
        ;;
    2)
        send_notification "Alice" "Hey! How are you doing today?" "chat-123456"
        ;;
    3)
        send_notification "Bob" "📷 sent you a photo" "chat-789012" "image"
        ;;
    4)
        send_notification "Project Team" "Charlie: Meeting at 3pm tomorrow" "group-345678" "group"
        ;;
    5)
        read -p "Enter badge count (0 to hide): " count
        set_badge "$count"
        ;;
    6)
        clear_notifications
        set_badge 0
        ;;
    7)
        echo -e "${BLUE}Running all notification tests...${NC}"
        echo ""
        
        send_notification "Welcome!" "Push notification system is working!" "test-1"
        sleep 2
        
        send_notification "Alice" "Hey there! 👋" "chat-001"
        sleep 2
        
        send_notification "Bob" "📷 sent you a photo" "chat-002"
        sleep 2
        
        send_notification "Work Group" "Sarah: Don't forget the meeting!" "group-001"
        sleep 2
        
        set_badge 3
        
        echo -e "${GREEN}✓ All tests completed!${NC}"
        echo -e "Check your notification panel for 4 notifications with badge counter showing 3"
        ;;
    8)
        read -p "Enter notification title: " title
        read -p "Enter notification message: " body
        read -p "Enter tag (optional): " tag
        send_notification "$title" "$body" "$tag"
        ;;
    *)
        echo "Invalid choice!"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${GREEN}Check your notification panel!${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
