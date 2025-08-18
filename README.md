# Ubuntu Touch Push Notification Demo

A simple Hello World app for Ubuntu Touch that demonstrates push notification functionality.

## Project Structure

```
pushnotification-demo/
├── manifest.json          # App manifest and metadata
├── pushnotification.desktop # Desktop entry file
├── pushnotification.apparmor # Security permissions
├── Main.qml               # Main application UI
├── pushnotification.png   # App icon (64x64 recommended)
└── README.md             # This file
```

## Prerequisites

1. **Ubuntu Touch Development Environment**:
   - Install clickable: `sudo snap install clickable --classic`
   - Or use the legacy Ubuntu SDK if preferred

2. **Device/Emulator**:
   - Ubuntu Touch device or emulator
   - Device must be in developer mode

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