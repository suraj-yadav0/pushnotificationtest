# Local Notification Testing Guide

This guide shows you how to test push notifications in your local development environment on Ubuntu Touch.

## 🚀 Quick Start

### Method 1: Interactive Python Tool (Recommended)

```bash
# Deploy your app first
clickable install

# Run the interactive test tool
./test-local-notifications.py
```

This gives you a menu to:
- Send simple notifications
- Test message notifications
- Test photo/group notifications
- Set badge counters
- Clear all notifications
- Run full test suite

### Method 2: Bash Script

```bash
# Deploy your app first
clickable install

# Run interactive menu
./send-local-notification.sh

# Or run specific tests directly
./send-local-notification.sh 1  # Simple notification
./send-local-notification.sh 7  # Run all tests
```

### Method 3: One-Line Commands

```bash
# Simple notification
./test-local-notifications.py simple

# Run all tests
./test-local-notifications.py test

# Set badge counter
./test-local-notifications.py badge 5

# Clear notifications
./test-local-notifications.py clear
```

## 📱 Testing on Device

### Step 1: Deploy Your App

```bash
# Build and install on connected device
clickable build
clickable install
```

### Step 2: Copy Test Scripts to Device

```bash
# Using ADB
adb push test-local-notifications.py /home/phablet/
adb push send-local-notification.sh /home/phablet/

# Make executable
adb shell chmod +x /home/phablet/test-local-notifications.py
adb shell chmod +x /home/phablet/send-local-notification.sh
```

### Step 3: Run Tests on Device

```bash
# SSH into device
ssh phablet@device-ip

# Or using ADB shell
adb shell

# Run the test tool
./test-local-notifications.py
```

## 🧪 Testing Scenarios

### 1. Simple Notification Test

```bash
./test-local-notifications.py simple
```

Creates a basic notification with title and message.

### 2. Chat Message Simulation

```bash
# Python
python3 test-local-notifications.py
# Choose option 2

# Bash
./send-local-notification.sh 2
```

Simulates a chat message from "Alice".

### 3. Photo/Media Notification

```bash
# Option 3 from interactive menu
./send-local-notification.sh 3
```

Simulates a photo message notification.

### 4. Badge Counter Test

```bash
# Set badge to 5
./test-local-notifications.py badge 5

# Clear badge
./test-local-notifications.py badge 0
```

### 5. Full Test Suite

```bash
./test-local-notifications.py test
```

Sends multiple notifications and sets badge counter.

## 🔍 Troubleshooting

### Notifications Don't Appear

1. **Check app is installed:**
   ```bash
   clickable install
   ```

2. **Verify D-Bus service is available:**
   ```bash
   gdbus introspect --session --dest com.lomiri.Postal \
       --object-path /com/lomiri/Postal/pushnotification_2esurajyadav
   ```

3. **Check logs:**
   ```bash
   # App logs
   clickable logs
   
   # System logs
   journalctl -f | grep -i postal
   ```

### Permission Errors

Make sure your app has the correct AppArmor permissions:
- `push-notification-client` policy group must be in `pushnotification.apparmor`

### D-Bus Errors

If you get "Service not found" errors:
1. Make sure your app is installed
2. Try launching the app at least once
3. Check the package name is correct: `pushnotification_2esurajyadav`

## 📝 Manual Testing with gdbus

You can also send notifications manually using gdbus:

```bash
APP_ID="pushnotification.surajyadav_pushnotification"
PKG_NAME="pushnotification_2esurajyadav"

# Send notification
gdbus call --session \
    --dest com.lomiri.Postal \
    --object-path "/com/lomiri/Postal/$PKG_NAME" \
    --method com.lomiri.Postal.Post \
    "$APP_ID" \
    '{"notification":{"card":{"summary":"Test","body":"Hello!","popup":true,"persist":true},"sound":true,"vibrate":true,"tag":"test"}}'

# Set badge counter
gdbus call --session \
    --dest com.lomiri.Postal \
    --object-path "/com/lomiri/Postal/$PKG_NAME" \
    --method com.lomiri.Postal.SetCounter \
    "$APP_ID" 5 true

# Clear notifications
gdbus call --session \
    --dest com.lomiri.Postal \
    --object-path "/com/lomiri/Postal/$PKG_NAME" \
    --method com.lomiri.Postal.ClearPersistent \
    "$APP_ID" ""
```

## 🎯 Testing Different Notification Types

### Text Message
```python
send_notification("Alice", "Hey! How's it going?", "chat-123")
```

### Photo
```python
send_notification("Bob", "📷 sent you a photo", "chat-456", "image")
```

### Group Message
```python
send_notification("Work Team", "Sarah: Meeting at 3pm", "group-789", "group")
```

### System Alert
```python
send_notification("System", "Update available", "system-001", "system")
```

## 🔄 Testing Notification Actions

### Deep Link Testing

1. Send notification with action:
   ```bash
   # Notification with deep link
   ./send-local-notification.sh 2
   ```

2. Tap the notification
3. Your app should open to the specific chat

### Clear Specific Notification

```bash
# Clear notification by tag
gdbus call --session \
    --dest com.lomiri.Postal \
    --object-path "/com/lomiri/Postal/pushnotification_2esurajyadav" \
    --method com.lomiri.Postal.ClearPersistent \
    "pushnotification.surajyadav_pushnotification" "chat-123"
```

## 📊 Verifying Notifications

### Check Notification Panel
1. Swipe down from top of screen
2. Look for your notifications
3. Verify badge counter on app icon

### Check Logs
```bash
# View notification events
journalctl -f --user | grep -i postal

# View app output
clickable logs
```

## 🎨 Customizing Test Notifications

Edit the Python script to add your own test cases:

```python
# In test-local-notifications.py
send_notification(
    title="Your Title",
    body="Your message here",
    tag="unique-tag",
    icon="your-icon"  # notification-symbolic, image, group, etc.
)
```

## 🚀 Next Steps

Once local testing works:
1. Set up your production server (see `server-example.py`)
2. Register at [Lomiri My Apps](https://myapps.lomiri.com/)
3. Get API credentials
4. Integrate with your backend
5. Send real push notifications from your server

## 📚 Additional Resources

- Original test script: `test-postal-notification.sh`
- Server example: `server-example.py`
- Main README: `README.md`
- Push helper source: `push/pushhelper.cpp`
