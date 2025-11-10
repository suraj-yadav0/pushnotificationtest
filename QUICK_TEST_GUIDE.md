# Quick Testing Guide - Push Notifications

## ✅ SUCCESS! Your notifications are working!

You just successfully sent notifications to your Ubuntu Touch device!

---

## 🚀 Quick Commands

### 1. Send a Simple Notification
```bash
adb shell '/home/phablet/quick-test.sh "Your message here"'
```

### 2. Run Full Test Suite (5 notifications + badge)
```bash
adb shell "/home/phablet/test-local-notifications.py test"
```

### 3. Send Single Test Notification
```bash
adb shell "/home/phablet/test-local-notifications.py simple"
```

### 4. Set Badge Counter
```bash
# Set badge to 3
adb shell "/home/phablet/test-local-notifications.py badge 3"

# Clear badge
adb shell "/home/phablet/test-local-notifications.py badge 0"
```

### 5. Clear All Notifications
```bash
adb shell "/home/phablet/test-local-notifications.py clear"
```

---

## 📱 Interactive Testing on Device

If you SSH into your device or use `adb shell`:

```bash
# SSH into device
ssh phablet@your-device-ip

# Or use ADB shell
adb shell

# Then run:
./test-local-notifications.py
```

This opens an interactive menu with options:
1. Simple notification
2. Message notification  
3. Photo notification
4. Group message
5. Set badge counter
6. Clear notifications
7. Run all tests
8. Custom notification
9. Exit

---

## 💡 Examples

### Example 1: Welcome Message
```bash
adb shell '/home/phablet/quick-test.sh "Welcome to Push Notifications"'
```

### Example 2: Chat Message
```bash
adb shell "/home/phablet/test-local-notifications.py simple"
```

### Example 3: Multiple Notifications
```bash
adb shell '/home/phablet/quick-test.sh "First message"'
sleep 1
adb shell '/home/phablet/quick-test.sh "Second message"'
sleep 1
adb shell '/home/phablet/quick-test.sh "Third message"'
```

### Example 4: Notification with Badge
```bash
# Send 3 notifications
adb shell "/home/phablet/test-local-notifications.py simple"
adb shell "/home/phablet/test-local-notifications.py simple"
adb shell "/home/phablet/test-local-notifications.py simple"

# Set badge counter to 3
adb shell "/home/phablet/test-local-notifications.py badge 3"
```

---

## 🔧 What's Happening Behind the Scenes

When you run these commands:
1. Script connects to `com.lomiri.Postal` D-Bus service
2. Creates notification JSON with title, body, sound, vibration settings
3. Posts to Postal service using `com.lomiri.Postal.Post` method
4. Lomiri displays the notification in the system panel
5. Badge counter updates app icon (if set)

---

## 📊 Verify Notifications

### On Your Device:
1. **Swipe down** from the top of the screen
2. Open the **notification panel**
3. You should see your notifications!
4. Check your app icon for the **badge counter** (red number)

### Via Logs:
```bash
# Watch notification activity
adb shell "journalctl -f --user | grep -i postal"

# Check app logs
clickable logs
```

---

## 🎯 Common Use Cases

### Testing During Development
```bash
# After each code change:
clickable build
clickable install
adb shell "/home/phablet/test-local-notifications.py test"
```

### Quick Smoke Test
```bash
# Just verify notifications work:
adb shell '/home/phablet/quick-test.sh "Test"'
```

### Badge Testing
```bash
# Test badge counter updates:
adb shell "/home/phablet/test-local-notifications.py badge 5"
# Check app icon for red "5" badge

adb shell "/home/phablet/test-local-notifications.py badge 0"
# Badge should disappear
```

---

## 🐛 Troubleshooting

### If notifications don't appear:

1. **App not installed:**
   ```bash
   clickable install
   ```

2. **Launch app at least once:**
   Open the app on your device manually

3. **Check D-Bus connection:**
   ```bash
   adb shell "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/32011/bus gdbus introspect --session --dest com.lomiri.Postal --object-path /com/lomiri/Postal/pushnotification_2esurajyadav"
   ```

4. **Check Lomiri is running:**
   ```bash
   adb shell "ps aux | grep lomiri"
   ```

### Emoji/Special Characters Issues:

The scripts now automatically remove emoji and special UTF-8 characters that gdbus can't handle. If you need emoji:
- Modify the notification in the app's push helper (C++ code)
- Or use basic ASCII characters only in test scripts

---

## 🎨 Customizing Notifications

### Edit the Python script to add your own tests:

```python
# In test-local-notifications.py, add to run_tests():
send_notification(
    title="My Custom Title",
    body="My custom message here",
    tag="custom-tag-001",
    icon="notification-symbolic"  # or: image, group, etc.
)
```

### Available icons:
- `notification-symbolic` (default)
- `image` (for photos)
- `group` (for group chats)
- `system` (for system alerts)

---

## 🚀 Next Steps

Now that local testing works:

1. ✅ **Local notifications working** - You're here!
2. 📝 **Integrate with your app** - Handle notification taps, deep links
3. 🌐 **Set up server** - Use `server-example.py` as template
4. 🔑 **Get API credentials** - Register at [Lomiri My Apps](https://myapps.lomiri.com/)
5. 📡 **Send real push notifications** - From your backend server

---

## 📝 Notes

- These test scripts send **local notifications** directly to the Postal service
- In production, notifications come from **your server** via the **Lomiri Push Service**
- The notification format is the same for both local and server-sent notifications
- Badge counters persist until manually cleared or app is updated

---

## 🎉 Success Checklist

- [x] App installed on device
- [x] Test scripts deployed
- [x] Notifications appearing in panel
- [x] Badge counter working
- [x] Sound/vibration working
- [ ] Deep linking (tap notification to open specific page)
- [ ] Server integration
- [ ] Production deployment

---

**Happy Testing! 🚀**

For more details, see:
- `LOCAL_TESTING.md` - Comprehensive testing guide
- `README.md` - Main project documentation
- `server-example.py` - Server integration example
