# Push Notification System for Ubuntu Touch

This project implements a comprehensive push notification mechanism for Ubuntu Touch, based on the TELEports notification system architecture. It provides rich, actionable notifications with proper badge management, avatar display, and deep linking capabilities.

## Features

- **Real-time Notifications**: Instant delivery through Ubuntu Touch's Postal service
- **Rich Content**: Support for multiple message types (text, media, stickers, etc.)
- **Smart Badge Management**: Accurate unread message counters
- **Deep Linking**: Direct navigation to specific content via URL dispatcher
- **Database Integration**: SQLite-based state management for avatars and unread counts
- **Internationalization**: Multi-language support ready
- **Security**: Proper AppArmor confinement for push helper

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Push Service   │    │  Ubuntu Touch    │    │   Push Helper   │
│  (Your Server)  │────│  Push Service    │────│   (C++ Binary)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                │                        │
                         ┌──────▼──────┐          ┌─────▼─────┐
                         │   Postal    │          │  AuxDB    │
                         │   Service   │          │ (SQLite)  │
                         └─────────────┘          └───────────┘
                                │
                                │
                         ┌──────▼──────┐
                         │ Notification │
                         │   Display    │
                         └─────────────┘
```

## Components

### 1. Push Helper Binary (`push/push.cpp`)
- Main entry point for processing incoming push notifications
- Converts push messages from your server format to Ubuntu Touch Postal format
- Handles message parsing, database updates, and notification generation

### 2. PostalClient (`common/auxdb/postal-client.cpp`)
- D-Bus interface to Ubuntu Touch's Postal service
- Manages badge counters and notification clearing
- Handles asynchronous D-Bus communication

### 3. AuxDatabase (`common/auxdb/auxdatabase.cpp`)
- SQLite database for managing notification state
- Stores chat avatars and unread message counts
- Supports database migration for future enhancements

### 4. AvatarMapTable (`common/auxdb/avatarmaptable.cpp`)
- Manages chat-specific avatars and unread counts
- Provides atomic operations for updating notification state
- Calculates total unread counts across all chats

## Supported Message Types

### Direct Messages
- `MESSAGE_TEXT`: Regular text messages
- `MESSAGE_PHOTO`: Photo messages
- `MESSAGE_VIDEO`: Video messages
- `MESSAGE_AUDIO`: Audio messages
- `MESSAGE_VOICE_NOTE`: Voice messages
- `MESSAGE_STICKER`: Sticker messages
- `MESSAGE_DOC`: Document messages
- `MESSAGE_CONTACT`: Contact sharing
- `MESSAGE_GEO`: Location sharing

### Group Messages
- `CHAT_MESSAGE_TEXT`: Group text messages
- `CHAT_MESSAGE_PHOTO`: Group photo messages
- `CHAT_CREATED`: Group creation events
- `CHAT_ADD_YOU`: User added to group
- And many more group-specific events

## Message Format

### Input (from your server)
```json
{
    "message": {
        "loc_key": "MESSAGE_TEXT",
        "loc_args": ["Sender Name", "Message content"],
        "badge": 1,
        "custom": {
            "from_id": "123456789"
        }
    }
}
```

### Output (to Ubuntu Touch Postal)
```json
{
    "notification": {
        "card": {
            "summary": "Sender Name",
            "body": "Message content",
            "popup": true,
            "persist": true,
            "actions": ["pushnotification://chat/123456789"],
            "icon": "notification-symbolic"
        },
        "sound": true,
        "tag": "123456789",
        "vibrate": true
    }
}
```

## Building and Installation

### Prerequisites
- Ubuntu Touch development environment
- Clickable installed
- CMake 3.16+
- Qt5 development libraries

### Build Steps
```bash
# Clone the repository
git clone <your-repo-url>
cd pushnotification

# Build the project
clickable build

# Install on Ubuntu Touch device
clickable install

# For desktop testing (limited functionality)
clickable desktop
```

### Testing
```bash
# Test the push helper with sample data
./test-push.sh

# Check database state
./debug-db.sh

# View build artifacts
ls -la build/x86_64-linux-gnu/app/install/
```

## Configuration Files

### Manifest (`manifest.json.in`)
```json
{
    "hooks": {
        "push": {
            "apparmor": "push/push-apparmor.json",
            "push-helper": "push/push-helper.json"
        }
    }
}
```

### Push Helper Config (`push/push-helper.json`)
```json
{
    "exec": "push"
}
```

### AppArmor Policy (`push/push-apparmor.json`)
```json
{
    "template": "ubuntu-push-helper",
    "policy_groups": ["push-notification-client"],
    "policy_version": 20.04
}
```

### URL Dispatcher (`pushnotification.url-dispatcher`)
```json
[
  {
    "protocol": "pushnotification"
  }
]
```

## Usage

### 1. Server Integration
Your server needs to send push notifications in this format:
```bash
curl -X POST https://push.ubuntu.com/notify \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "appid": "pushnotification.surajyadav_pushnotification",
    "expire_on": "2025-12-31T23:59:59.999Z",
    "token": "USER_DEVICE_TOKEN",
    "clear_pending": true,
    "replace_tag": "chat_123456789",
    "data": {
      "message": {
        "loc_key": "MESSAGE_TEXT",
        "loc_args": ["John Doe", "Hello from server!"],
        "badge": 1,
        "custom": {
          "from_id": "123456789"
        }
      }
    }
  }'
```

### 2. Chat ID Format
- **Private chats**: Use user ID directly (positive number)
- **Basic groups**: Group ID × -1 (negative number)  
- **Supergroups**: (Channel ID + 1000000000000) × -1

### 3. Deep Linking
When users tap notifications, your app receives URLs like:
- `pushnotification://chat/123456789` (private chat)
- `pushnotification://chat/-987654321` (group chat)

Handle these in your main QML:
```qml
Connections {
    target: Qt.application
    onStateChanged: {
        if (Qt.application.state === Qt.ApplicationActive) {
            // Parse URL and navigate to specific chat
        }
    }
}
```

## Database Schema

```sql
CREATE TABLE `chatlist_map` (
    `id` INTEGER NOT NULL UNIQUE,        -- Chat ID
    `path` TEXT NOT NULL,                -- Avatar file path
    `unread_messages` INTEGER,           -- Unread count
    PRIMARY KEY(id)
);
```

## Debugging

### Common Issues

1. **No notifications appearing**: Check AppArmor policy and push-helper configuration
2. **Wrong badge count**: Verify database unread counts with `debug-db.sh`
3. **D-Bus errors**: Normal on desktop; only works on Ubuntu Touch devices
4. **Build failures**: Ensure all Qt5 dependencies are installed

### Debug Tools
```bash
# Check push helper logs
journalctl -f | grep push

# Test D-Bus connection (Ubuntu Touch only)
busctl list | grep Postal

# Verify database state
./debug-db.sh

# Test notification processing
./test-push.sh
```

## Security Considerations

- Push helper runs under strict AppArmor confinement
- Database files have restricted permissions
- No network access from push helper
- Input validation for all JSON parsing
- Secure D-Bus communication

## Extending the System

### Adding New Message Types
1. Add the new `loc_key` to `formatNotificationMessage()` in `pushhelper.cpp`
2. Define appropriate body text and internationalization strings
3. Update tests and documentation

### Custom Avatar Support
1. Store avatar paths in `chatlist_map` table
2. Update `getAvatarPathbyId()` to return custom paths
3. Ensure proper file permissions for avatar files

### Advanced Badge Management
1. Extend database schema for per-chat settings
2. Add methods to `AvatarMapTable` for custom badge logic
3. Update `getTotalUnread()` calculation as needed

## License

This project is licensed under the GNU General Public License v3.0. See LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## Support

For issues and questions:
- Check the debugging section above
- Review the TELEports documentation (included)
- Open an issue on the project repository
- Test on actual Ubuntu Touch devices for full functionality

---

**Note**: This notification system is designed specifically for Ubuntu Touch. Desktop testing provides limited functionality since the Postal service and push infrastructure are only available on Ubuntu Touch devices.
