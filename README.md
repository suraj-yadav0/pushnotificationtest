# Lomiri Push Notification Demo

A comprehensive demo app for Lomiri (Ubuntu Touch) that demonstrates **real system notifications** using the Lomiri Push Service and Postal Service.

## Features

- ✅ **Real System Notifications**: Notifications appear in the Lomiri notification panel
- ✅ **Push Service Integration**: Uses Lomiri.PushNotifications for device registration
- ✅ **Postal Service Delivery**: Notifications delivered via com.lomiri.Postal service
- ✅ **Deep Linking**: Tap notifications to open specific chats/messages
- ✅ **Badge Counter**: Shows unread notification count
- ✅ **Persistent Notifications**: Notifications remain until dismissed

## How System Notifications Work

Unlike traditional Android/iOS apps, Lomiri uses a **server-mediated push system**:

1. **App Registration**: App registers with Lomiri Push Service to get device token
2. **Server Push**: Your server sends notifications to the device token
3. **Postal Delivery**: Push service delivers to Postal service, which creates system notification
4. **User Interaction**: System displays notification in panel with sound/vibration

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