# Complete Notification System Analysis & Fix

## 🔍 Problem Analysis

**Issue**: Notifications not appearing in notification panel, badge not showing on app icon

**Root Cause**: The app was using `com.lomiri.Postal.Post` which is for internal postal service messaging, NOT for displaying notifications.

---

## ✅ Solution Implemented

### 1. **For Notification Panel Display**
- **Service**: `org.freedesktop.Notifications`
- **Method**: `Notify(app_name, replaces_id, icon, summary, body, actions, hints, timeout)`
- **Purpose**: Actually displays notifications in the notification panel

### 2. **For Badge Counter (App Icon)**
- **Service**: `com.lomiri.Postal`
- **Method**: `SetCounter(app_id, count, visible)`  
- **Purpose**: Shows red badge with number on app icon

### 3. **Architecture**
```
Push Message → Push Helper (C++) → Two Services:
├── org.freedesktop.Notifications → Notification Panel ✅
└── com.lomiri.Postal.SetCounter → App Icon Badge ✅
```

---

## 📂 Files Modified

### New Files Created:
1. **`common/auxdb/notification-client.h`** - Header for notification client
2. **`common/auxdb/notification-client.cpp`** - D-Bus client for org.freedesktop.Notifications

### Files Updated:
1. **`common/auxdb/CMakeLists.txt`** - Added notification-client to build
2. **`push/pushhelper.h`** - Added NotificationClient member
3. **`push/pushhelper.cpp`** - Updated to use NotificationClient for notifications
4. **`test-local-notifications.py`** - Uses freedesktop.Notifications
5. **`quick-test.sh`** - Uses freedesktop.Notifications
6. **`send-local-notification.sh`** - Uses freedesktop.Notifications

---

## 🎯 How It Works Now

### C++ Push Helper (`push/pushhelper.cpp`)

```cpp
void PushHelper::process()
{
    // 1. Read incoming push message
    QJsonObject pushMessage = readPushMessage(mInfile);
    
    // 2. Extract notification data
    QString summary = locArgs[0].toString();  // e.g., "Alice"
    QString body = formatNotificationMessage(locKey, locArgs);  // e.g., "Hey!"
    
    // 3. Send to notification panel
    m_notificationClient->notify(summary, body, icon);
    // ✅ This displays in notification panel!
    
    // 4. Update badge counter
    if (badge > 0) {
        m_postalClient->setCount(totalCount);
        // ✅ This shows number on app icon!
    }
}
```

### NotificationClient (New)

```cpp
void NotificationClient::notify(const QString &summary, const QString &body,
                               const QString &icon, ...)
{
    QDBusMessage message = QDBusMessage::createMethodCall(
        "org.freedesktop.Notifications",
        "/org/freedesktop/Notifications",
        "org.freedesktop.Notifications",
        "Notify");
    
    QList<QVariant> args;
    args << m_appId;        // "pushnotification.surajyadav_pushnotification"
    args << (uint)0;        // replaces_id (0 = new)
    args << icon;           // "notification"
    args << summary;        // "Alice"
    args << body;           // "Hey! How are you?"
    args << actions;        // []
    args << hints;          // {}
    args << timeout;        // 5000 (5 seconds)
    
    bus.asyncCall(message);
}
```

---

## 🧪 Testing

### Test 1: Notification Panel
```bash
./send-test-notification.sh "Test message"
```

**Expected Result**:
- ✅ Notification appears in panel
- ✅ Title: "Push Test"
- ✅ Body: "Test message"
- ✅ Returns notification ID: `(uint32 15,)`

### Test 2: Badge Counter
```bash
adb shell "/home/phablet/test-local-notifications.py badge 3"
```

**Expected Result**:
- ✅ Red badge with "3" appears on app icon
- ✅ Message: "✓ Badge counter updated!"

### Test 3: Full Test Suite
```bash
adb shell "/home/phablet/test-local-notifications.py test"
```

**Expected Result**:
- ✅ 5 notifications in panel
- ✅ Badge shows "5"
- ✅ All tests pass

### Test 4: App Icon Badge
```bash
# Set badge to different values
adb shell "/home/phablet/test-local-notifications.py badge 1"
adb shell "/home/phablet/test-local-notifications.py badge 5"
adb shell "/home/phablet/test-local-notifications.py badge 10"

# Clear badge
adb shell "/home/phablet/test-local-notifications.py badge 0"
```

**Expected Result**:
- ✅ Badge number changes on app icon
- ✅ Badge disappears when set to 0

---

## 📱 Verification Steps

### On Your Device:

1. **Check Notification Panel**:
   - Swipe down from top
   - Should see notifications with:
     - Title (e.g., "Push Test", "Alice")
     - Body message
     - Icon
   
2. **Check App Icon**:
   - Look at app launcher
   - Should see red badge with number
   - Number changes when you set different badge values

3. **Test Real Push Message**:
   ```bash
   # Send test message
   ./send-test-notification.sh "Real test notification"
   
   # Immediately check:
   # - Notification panel (swipe down)
   # - App icon badge (if badge was set)
   ```

---

## 🔧 Technical Details

### D-Bus Services Used

#### For Notifications:
```
Service: org.freedesktop.Notifications
Path: /org/freedesktop/Notifications
Interface: org.freedesktop.Notifications
Method: Notify

Returns: uint32 notification_id
```

#### For Badge Counter:
```
Service: com.lomiri.Postal
Path: /com/lomiri/Postal/pushnotification_2esurajyadav
Interface: com.lomiri.Postal
Method: SetCounter

Arguments: app_id, count, visible
```

### Build System

```bash
# Clean build
clickable clean
clickable build

# Install on device
clickable install

# Test
./send-test-notification.sh "Test"
```

---

## 🎨 Customization

### Change Notification Icon
Edit `pushhelper.cpp`:
```cpp
// Default icon
QString avatar = "notification";

// For photos
QString avatar = "image";

// For messages
QString avatar = "message";

// For groups
QString avatar = "group";
```

### Change Notification Timeout
Edit `notification-client.cpp`:
```cpp
// 5 seconds
m_notificationClient->notify(summary, body, icon, actions, hints, 5000);

// 10 seconds
m_notificationClient->notify(summary, body, icon, actions, hints, 10000);

// Never expire
m_notificationClient->notify(summary, body, icon, actions, hints, -1);
```

### Add Notification Actions
```cpp
QStringList actions;
actions << "open" << "Open" << "dismiss" << "Dismiss";
m_notificationClient->notify(summary, body, icon, actions, hints, 5000);
```

---

## 📊 Current Status

### ✅ Working:
- Notifications appear in notification panel
- Badge counter shows on app icon
- Multiple notifications supported
- Each notification gets unique ID
- Sound and vibration (system handles this)
- Test scripts work from development machine

### 🎯 TODO for Production:
1. Add notification tap handling (deep links)
2. Add quick reply actions
3. Add notification grouping
4. Integrate with real push server
5. Handle notification permissions
6. Add notification categories (message, photo, etc.)

---

## 🐛 Troubleshooting

### Notifications Still Not Appearing?

1. **Rebuild and reinstall**:
   ```bash
   clickable clean
   clickable build
   clickable install
   ```

2. **Check D-Bus connection**:
   ```bash
   adb shell "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/32011/bus gdbus introspect --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications"
   ```

3. **Test directly**:
   ```bash
   ./send-test-notification.sh "Direct test"
   ```

4. **Check logs**:
   ```bash
   clickable logs
   ```

### Badge Not Showing?

1. **Test badge directly**:
   ```bash
   adb shell "/home/phablet/test-local-notifications.py badge 5"
   ```

2. **Check Postal service**:
   ```bash
   adb shell "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/32011/bus dbus-send --session --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames | grep Postal"
   ```

---

## 📝 Summary

**Before**: No notifications, no badge
**After**: ✅ Notifications in panel, ✅ Badge on icon

**Key Changes**:
1. Created `NotificationClient` for org.freedesktop.Notifications
2. Updated `PushHelper` to use both services
3. Notifications → org.freedesktop.Notifications.Notify
4. Badge → com.lomiri.Postal.SetCounter

**Test Commands**:
```bash
# Quick test
./send-test-notification.sh "Hello"

# Full test
adb shell "/home/phablet/test-local-notifications.py test"

# Badge test
adb shell "/home/phablet/test-local-notifications.py badge 3"
```

**Result**: Complete working notification system for Ubuntu Touch! 🎉
