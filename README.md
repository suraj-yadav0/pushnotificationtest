# Lomiri Push Notification Demo

A comprehensive demo app for Lomiri (Ubuntu Touch) that demonstrates **real system notifications** using the Lomiri Push Service and Postal Service.

## Features

- ✅ **Real System Notifications**: Notifications appear in the Lomiri notification panel
- ✅ **Push Service Integration**: Uses Lomiri.PushNotifications for device registration
- ✅ **Postal Service Delivery**: Notifications delivered via com.lomiri.Postal service
- ✅ **Deep Linking**: Tap notifications to open specific chats/messages
- ✅ **Badge Counter**: Shows unread notification count with avatar support
- ✅ **Persistent Notifications**: Notifications remain in notification center
- ✅ **Sound & Vibration**: System-wide audio and haptic feedback
- ✅ **D-Bus Integration**: Low-level D-Bus communication for Postal service

---

## 🔄 Complete Push Notification Flow

### Overview: From Server to System Notification

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PUSH NOTIFICATION DELIVERY PIPELINE                      │
└─────────────────────────────────────────────────────────────────────────────┘

                              EXTERNAL SERVER
                                    │
                                    │ 1. HTTP POST with
                                    │    device token
                                    ▼
                        ┌──────────────────────────┐
                        │ Lomiri Push Service      │
                        │ push.lomiri.com/notify   │
                        └───────────┬──────────────┘
                                    │
                                    │ 2. Route to device
                                    ▼
                        ┌──────────────────────────┐
                        │ UBUNTU TOUCH DEVICE      │
                        └───────────┬──────────────┘
                                    │
                ┌───────────────────┼───────────────────┐
                │                   │                   │
                ▼                   ▼                   ▼
        ┌──────────────┐    ┌──────────────┐   ┌──────────────┐
        │  Framework   │    │   Manifest   │   │ Push Helper  │
        │ (receives)   │    │   (triggers) │   │ (processes)  │
        └──────┬───────┘    └──────┬───────┘   └──────┬───────┘
               │                   │                   │
               └───────────────────┴───────────────────┘
                            │
                            │ 3. Execute push-helper
                            │    with JSON message
                            ▼
                  ┌────────────────────────┐
                  │   push-helper binary   │
                  │ (pushhelper.cpp)       │
                  │                        │
                  │ • Parse JSON           │
                  │ • Format message       │
                  │ • Extract chat ID      │
                  │ • Get avatar          │
                  └───────────┬────────────┘
                              │
                ┌─────────────┬─────────────┐
                │             │             │
                ▼             ▼             ▼
        ┌────────────┐ ┌────────────┐ ┌──────────────┐
        │ org.freed  │ │com.lomiri. │ │ AuxDB        │
        │ esktop     │ │ Postal     │ │ (local DB)   │
        │.Notifcat  │ │ service    │ │              │
        │ ions       │ │            │ │ • avatars    │
        │            │ │ • Post()   │ │ • chat IDs   │
        │ • popup    │ │ • SetCount │ │ • unread     │
        │ • transient│ │            │ │   counts     │
        └────────────┘ └────────────┘ └──────────────┘
                │             │
                └─────────────┴────────────┐
                                          │
                                          ▼
                            ┌──────────────────────────┐
                            │ SYSTEM NOTIFICATION      │
                            │ • Visible in panel       │
                            │ • Sound + Vibration      │
                            │ • Badge counter          │
                            │ • Deep linking (actions) │
                            └──────────────────────────┘
```

---

## 🎯 Detailed Component Flow

### 1. **App Registration & Token Acquisition** (QML)

```qml
// Main.qml - PushClient registration
PushNotifications.PushClient {
    id: pushClient
    appId: "pushnotification.surajyadav_pushnotification"
    
    onTokenChanged: {
        // Token received from Lomiri Push Service
        // Store this token on your server
        console.log("Device token:", token)
    }
    
    onMessageReceived: {
        // Handle incoming push messages
        handlePushMessage(message)
    }
}
```

**What happens:**

- App requests registration from Lomiri Push Service
- Service generates unique device token
- Token passed back to app via `onTokenChanged` signal
- App displays token for server registration

---

### 2. **Server Sends Notification** (Python)

```python
# server-example.py - Sending the notification
payload = {
    "appid": "pushnotification.surajyadav_pushnotification",
    "token": device_token,              # From step 1
    "expire_on": expire_time.isoformat() + "Z",
    "data": {
        "message": {
            "loc_key": "MESSAGE_TEXT",
            "loc_args": ["Alice", "Hey there!"],
            "badge": 1,
            "custom": {"from_id": "123456"}
        }
    }
}

# POST to Lomiri Push Service
response = requests.post("https://push.lomiri.com/notify", 
                        json=payload,
                        headers=headers)
```

**What happens:**

- Server prepares message with target app ID and device token
- Message includes localized key and arguments
- Custom data for deep linking
- HTTP POST sent to Lomiri Push Service API

---

### 3. **Push Service Routes to Device**

Lomiri Push Service:

- Validates app ID & credentials
- Looks up device token
- Routes message to device
- Persists if offline
- Retries on delivery failure

**Device receives:**

```json
{
    "message": {
        "loc_key": "MESSAGE_TEXT",
        "loc_args": ["Alice", "Hey there!"],
        "badge": 1,
        "custom": {"from_id": "123456"}
    }
}
```

---

### 4. **Push Helper Processing** (C++ - Core Logic)

**File: `push/push.cpp`** - Entry point

```cpp
int main(int argc, char *argv[])
{
    // Arguments: program [input_file] [output_file]
    // Example: push /tmp/push.in.json /tmp/push.out.json
    
    PushHelper pushHelper("pushnotification.surajyadav_pushnotification",
                          args.at(1),  // input file
                          args.at(2),  // output file
                          &app);
    
    pushHelper.process();  // Main processing
}
```

**File: `push/pushhelper.cpp`** - Message processing & notification delivery

```cpp
void PushHelper::process()
{
    // STEP 1: Read incoming push message from file
    QJsonObject pushMessage = readPushMessage(mInfile);
    
    // STEP 2: Parse message structure
    QJsonObject message = pushMessage["message"].toObject();
    QString locKey = message["loc_key"].toString();
    QJsonArray locArgs = message["loc_args"].toArray();
    int badge = message["badge"].toInt();
    
    // STEP 3: Extract chat ID from custom data
    qint64 chatId = extractChatId(message["custom"].toObject());
    
    // STEP 4: Get sender name (first argument)
    QString summary = locArgs[0].toString();
    
    // STEP 5: Format notification body based on message type
    QString body = formatNotificationMessage(locKey, locArgs);
    // Example: locKey="MESSAGE_TEXT" → "Alice: Hey there!"
    
    // STEP 6: Get avatar from local database
    QString avatar = m_auxdb.getAvatarMapTable()->getAvatarPathbyId(chatId);
    
    // STEP 7: Generate unique notification tag
    QString tag = QString("chat_%1").arg(chatId);
    
    // STEP 8: Update unread badge counter
    m_auxdb.getAvatarMapTable()->setUnreadMapEntry(chatId, badge);
    qint32 totalCount = m_auxdb.getAvatarMapTable()->getTotalUnread();
    m_postalClient->setCount(totalCount);  // Update badge in UI
    
    // STEP 9a: Send transient popup notification
    m_notificationClient->notify(summary, body, avatar);
    
    // STEP 9b: Send persistent notification via Postal service
    m_postalClient->postNotification(tag, summary, body, avatar);
    
    // STEP 10: Write output file (Ubuntu Touch protocol requirement)
    writeOutputFile(summary, body, avatar, tag, totalCount);
}
```

---

### 5. **Postal Service Integration** (D-Bus)

**File: `common/auxdb/postal-client.cpp`** - D-Bus communication

```cpp
void PostalClient::post(const QString &message)
{
    // Create D-Bus method call
    QDBusMessage dbusMessage = QDBusMessage::createMethodCall(
        "com.lomiri.Postal",                    // Service
        "/com/lomiri/Postal/pushnotification",  // Object path
        "com.lomiri.Postal",                    // Interface
        "Post"                                  // Method
    );
    
    // Parameters: app_id, message_json
    dbusMessage << "pushnotification.surajyadav_pushnotification" << message;
    
    // Send asynchronously
    QDBusPendingCall pcall = bus.asyncCall(dbusMessage);
    // Handle response...
}

void PostalClient::postNotification(const QString &tag, 
                                    const QString &summary, 
                                    const QString &body, 
                                    const QString &icon)
{
    // Build notification in Postal format
    QJsonObject card;
    card["summary"] = summary;      // "Alice"
    card["body"] = body;            // "Hey there!"
    card["icon"] = icon;            // Avatar path
    card["persist"] = true;         // Stay in notification center
    card["popup"] = true;           // Show as popup banner
    card["vibrate"] = true;         // Haptic feedback
    card["sound"] = true;           // Audio feedback
    
    QJsonObject notification;
    notification["card"] = card;
    notification["tag"] = tag;      // Unique identifier
    
    // Send to Postal service
    QJsonDocument doc(notification);
    post(QString::fromUtf8(doc.toJson(QJsonDocument::Compact)));
}

void PostalClient::setCount(int count)
{
    // Update app badge counter
    // Example: Shows "3" unread messages
    QDBusMessage message = QDBusMessage::createMethodCall(
        "com.lomiri.Postal",
        "/com/lomiri/Postal/pushnotification",
        "com.lomiri.Postal",
        "SetCounter"
    );
    
    message << "pushnotification.surajyadav_pushnotification" 
            << count 
            << (count != 0);  // visible flag
    
    bus.asyncCall(message);
}
```

**D-Bus Communication Details:**

```text
Service:  com.lomiri.Postal
Object:   /com/lomiri/Postal/pushnotification_surajyadav
          (converted from: pushnotification.surajyadav)
          (dots → underscores, hyphens → underscores+2d)

Methods:
├─ Post(string app_id, string message)
│  └─ Posts JSON notification to notification panel
├─ SetCounter(string app_id, int count, bool visible)
│  └─ Updates badge counter
└─ ClearPersistent(string app_id, string... tags)
   └─ Removes specific notifications
```

---

### 6. **System Notification Display**

**Postal Service creates:**

- ✅ Persistent notification in notification center
- ✅ Popup banner at top of screen
- ✅ Sound notification (default notification sound)
- ✅ Vibration feedback
- ✅ Badge counter on app icon

**User sees:**

```
Top banner:  ┌─────────────────────────┐
             │ 🔔 Alice: Hey there!    │
             │ Avatar | Notification   │
             └─────────────────────────┘

Notification center:
┌──────────────────────────────────────┐
│ Yesterday                            │
│ ┌────────────────────────────────────┤
│ │ 🔔 Alice                          │
│ │ Hey there!                        │
│ │ (tap to open chat)                │
│ └────────────────────────────────────┤
└──────────────────────────────────────┘

App icon: [📱³]  ← Badge showing "3" unread
```

---

## How System Notifications Work

Unlike traditional Android/iOS apps, Lomiri uses a **server-mediated push system**:

1. **App Registration**: App registers with Lomiri Push Service to get device token
2. **Server Push**: Your server sends notifications to the device token via Lomiri API
3. **Message Routing**: Push service routes notification to device's push-helper
4. **Local Processing**: push-helper processes JSON and posts to Postal service
5. **D-Bus Posting**: Postal service displays notification in system panel
6. **User Interaction**: System displays notification with sound/vibration/badge

## Project Structure

```
pushnotification/
├── manifest.json.in           # App manifest with push hooks
├── pushnotification.apparmor  # Security permissions (push-notification-client)
├── qml/Main.qml              # Main UI with Lomiri.PushNotifications integration
├── push/                     # Native push processing
│   ├── push.cpp             # Push helper entry point
│   ├── pushhelper.cpp       # Message processing and Postal posting
│   └── push-helper.json     # Push helper configuration
├── common/auxdb/            # Postal service client
│   ├── postal-client.cpp    # D-Bus interface to com.lomiri.Postal
│   └── postal-client.h      # Postal service methods
├── push-helper              # Bash script for push message handling
├── server-example.py        # Python server for sending push notifications
├── test-postal-notification.sh # Test script for direct Postal notifications
└── README.md
```

## Testing System Notifications

### Method 1: Direct Postal Service Test

Test notifications without needing a server:

```bash
# Run this on your Ubuntu Touch device/emulator
./test-postal-notification.sh
```

This will create a system notification using the Postal service directly.

### Method 2: Full Push Service Test

For complete end-to-end testing:

1. **Register your app** at [Lomiri My Apps](https://myapps.lomiri.com/)
2. **Get API credentials** from the dashboard
3. **Deploy the app** to your device
4. **Run the app** to get the device token (shown in app UI)
5. **Send test notifications**:

```bash
python3 server-example.py \
    --app-id pushnotification.surajyadav_pushnotification \
    --token YOUR_DEVICE_TOKEN \
    --auth YOUR_API_TOKEN \
    --message "Hello from server!" \
    --sender "Test Server"
```

### Method 3: In-App Testing

The app includes buttons to test in-app notifications and push registration.

## Key Implementation Details

### Push Service Registration

```qml
import Lomiri.PushNotifications 0.1 as PushNotifications

PushNotifications.PushClient {
    appId: "pushnotification.surajyadav_pushnotification"
    
    onTokenChanged: {
        // Send token to your server
        console.log("Device token:", token)
    }
    
    onMessageReceived: {
        // Handle incoming push messages
        handlePushMessage(message)
    }
}
```

### Postal Service Notification

```cpp
// In pushhelper.cpp
QJsonDocument doc(postalMessage);
QString messageJson = doc.toJson(QJsonDocument::Compact);
m_postalClient->post(messageJson);  // Posts to com.lomiri.Postal.Post
```

### Notification Format

```json
{
    "notification": {
        "card": {
            "summary": "Notification Title",
            "body": "Notification message text",
            "popup": true,
            "persist": true
        },
        "sound": true,
        "vibrate": true,
        "tag": "unique-notification-id"
    }
}
```

## Setup Instructions

1. **Create the project directory**:

```bash
mkdir pushnotification-demo
cd pushnotification-demo
```

2. **Create the files** using the provided code artifacts
3. **Add an app icon**:
   - Create a 64x64 PNG icon named `pushnotification.png`
   - Place it in the project root directory
4. **Initialize clickable (if using clickable)**:

```bash
clickable create
```

## Building and Installation

### Using Clickable (Recommended)

1. **Build the app**:

```bash
clickable build
```

2. **Install on device**:

```bash
clickable install
```

3. **Run on device**:

```bash
clickable launch
```

### Manual Build (Legacy)

1. **Create click package**:

```bash
click build .
```

2. **Install on device**:

```bash
adb push *.click /tmp/
adb shell
pkcon install-local --allow-untrusted /tmp/your-app.click
```

## How It Works

### Push Notification Flow

1. **App Registration**: The app registers with Ubuntu Push Service using `PushClient`
2. **Token Generation**: Upon successful registration, a unique token is generated
3. **Server Integration**: In production, you'd send this token to your server
4. **Notification Delivery**: Your server uses Ubuntu Push Service API to send notifications

### Key Components

- **PushClient**: QML component that handles push notification registration
- **Button Handler**: Simulates sending a notification (in production, this would trigger server-side logic)
- **Status Display**: Shows registration status and token information

## Production Implementation

To implement real push notifications:

1. **Server Setup**: Create a server that can communicate with Ubuntu Push Service
2. **Token Management**: Store device tokens on your server
3. **Push Service Integration**: Use Ubuntu Push Service API to send notifications
4. **Message Handling**: Implement proper message parsing in the app

### Ubuntu Push Service API

Your server needs to make HTTP requests to:

```
POST https://push.ubuntu.com/notify
```

With proper authentication and message payload.

## Testing

1. **Local Testing**: The app includes a test button that simulates notification behavior
2. **Device Testing**: Install on an actual Ubuntu Touch device for real push testing
3. **Log Monitoring**: Check console logs for registration status and errors

## Troubleshooting

### Common Issues

1. **Registration Fails**:
   - Check internet connectivity
   - Verify apparmor permissions include `push-notification-client`
   - Ensure device has access to Ubuntu Push Service

2. **App Won't Install**:
   - Check manifest.json syntax
   - Verify all required files are present
   - Ensure proper file permissions

3. **Notifications Not Received**:
   - Verify app is properly registered
   - Check server-side implementation
   - Ensure push service is accessible

### Debug Commands

```bash
# Check app logs
clickable logs

# Monitor system logs
adb logcat | grep -i push

# Check app installation
click list --user
```

## Security Notes

- The app requests minimal permissions (`networking` and `push-notification-client`)
- Push tokens should be handled securely on your server
- Never expose push service credentials in client-side code

## Next Steps

1. Set up a backend server
2. Implement proper push message handling
3. Add notification actions and rich content
4. Test on multiple devices
5. Implement proper error handling and retry logic

## Resources

- [Ubuntu Touch Documentation](https://docs.ubuntu.com/phone/en/)
- [Ubuntu Push Service API](https://developer.ubuntu.com/en/phone/platform-guides/push-notifications-server-guide/)
- [QML Push Notifications](https://developer.ubuntu.com/en/phone/apps/qml/api-qml-current/Ubuntu.PushNotifications/)
- [Clickable Documentation](https://clickable-ut.dev/)
