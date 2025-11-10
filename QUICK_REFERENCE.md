# Quick Reference: Push Notification System

## 🎯 5-Minute Overview

Your Lomiri push notification system works like this:

```
Server POST → Lomiri Cloud → Device → Push Helper → Postal Service → Notification
   1-2s        0.5s          0.5s      0.1-0.2s       0.05s            instant
```

---

## The 6 Steps

### 1️⃣ Server Sends Message (Python)

```python
import requests

payload = {
    "appid": "pushnotification.surajyadav_pushnotification",
    "token": "device_token_from_app",
    "expire_on": "2025-11-11T10:30:00Z",
    "data": {
        "message": {
            "loc_key": "MESSAGE_TEXT",
            "loc_args": ["Alice", "Hey!"],
            "badge": 1,
            "custom": {"from_id": "123456"}
        }
    }
}

requests.post("https://push.lomiri.com/notify", json=payload)
```

**Key fields:**
- `appid` - Your app ID
- `token` - Unique device token from app registration
- `loc_key` - Message type (MESSAGE_TEXT, MESSAGE_PHOTO, etc.)
- `loc_args` - Message text parameters
- `badge` - Unread count
- `custom` - App-specific data for deep linking

---

### 2️⃣ Lomiri Push Service Routes (Cloud)

**What happens:**
- Validates app ID and auth token
- Looks up device token in database
- Sends message to device network
- If offline: stores and retries for 24 hours
- If expired: discards

---

### 3️⃣ Device Receives Message (Ubuntu Touch Framework)

**What happens:**
- Framework receives message from push service
- Reads manifest.json to find push-helper
- Executes: `push /tmp/message.in.json /tmp/message.out.json`

**Configuration in manifest.json:**
```json
{
    "hooks": {
        "push": {
            "push-helper": "push/push-helper.json"
        }
    }
}
```

---

### 4️⃣ Push Helper Processes (C++ - pushhelper.cpp)

**10 steps:**

1. **Read** input JSON file
2. **Parse** message fields (loc_key, loc_args, badge, custom)
3. **Extract** chat ID from custom data
4. **Get** sender name (first argument)
5. **Format** notification text based on message type
6. **Get** avatar from local AuxDB database
7. **Generate** unique tag for notification
8. **Update** badge counter in AuxDB
9. **Post** to Postal service via D-Bus
10. **Write** output JSON file

**Key code:**
```cpp
// Read message
QJsonObject msg = readPushMessage(inputFile);

// Extract fields
QString locKey = msg["message"]["loc_key"];
QJsonArray args = msg["message"]["loc_args"];
int badge = msg["message"]["badge"];

// Format notification
QString summary = args[0].toString();  // "Alice"
QString body = formatMessage(locKey, args);  // "Alice: Hey!"

// Get avatar
QString avatar = getAvatarFor(chatId);

// Post to Postal
m_postalClient->postNotification(tag, summary, body, avatar);

// Update badge
m_postalClient->setCount(totalUnread);
```

---

### 5️⃣ Postal Service Posts (D-Bus)

**What happens:**
- Receives D-Bus call from push-helper
- Creates notification JSON
- Posts to system
- Plays sound
- Vibrates device
- Updates badge icon

**D-Bus Calls:**

**A. Post Notification:**
```
Service: com.lomiri.Postal
Method: Post(app_id, json_notification)
```

**B. Set Badge:**
```
Service: com.lomiri.Postal
Method: SetCounter(app_id, count, visible)
```

---

### 6️⃣ System Shows Notification (Lomiri Shell)

**User sees:**

- **Top banner** (5 seconds):
  ```
  ┌──────────────────────┐
  │ 🔔 Alice             │
  │ Hey!                 │
  └──────────────────────┘
  ```

- **Notification center** (persistent):
  ```
  📱 Alice
  Hey!
  [tap to open chat]
  ```

- **App badge**: `[📱¹]`

- **Sound**: System notification sound
- **Vibration**: Haptic feedback

---

## Key Components

### Files & Directories

| File | Purpose |
|------|---------|
| `server-example.py` | Send push from server |
| `push/push.cpp` | Push helper entry |
| `push/pushhelper.cpp` | Message processing |
| `common/auxdb/postal-client.cpp` | D-Bus communication |
| `push/push-helper.json` | Config: exec: "push" |
| `qml/Main.qml` | App UI, token registration |

### Key Classes

| Class | File | Purpose |
|-------|------|---------|
| `PushHelper` | pushhelper.cpp | Process message, post notification |
| `PostalClient` | postal-client.cpp | D-Bus communication |
| `AvatarMapTable` | auxdatabase.cpp | Store chat ID ↔ avatar mappings |
| `PushClient` | Main.qml | Register with push service |

---

## Message Types (loc_key)

```
"MESSAGE_TEXT" → "{sender}: {message}"
Example: "Alice: Hey there!"

"MESSAGE_PHOTO" → "{sender} sent a photo"
Example: "Bob sent a photo"

"CHAT_MESSAGE_TEXT" → "{sender} in {group}: {message}"
Example: "Charlie in Friends: Anyone up?"

"CHAT_ADD_YOU" → "{sender} added you to {group}"
Example: "Dave added you to Book Club"

"" → (no notification)
"READ_HISTORY" → (skip)
```

---

## Database (AuxDB)

Local SQLite database stores:

```sql
-- Avatar mapping
chat_id | avatar_path | unread_count
123456  | /path/alice | 1
789012  | /path/bob   | 0

-- Used by push helper to:
-- 1. Get avatar for notification
-- 2. Update unread count
-- 3. Calculate total badge number
```

---

## D-Bus Communication

**Post Notification:**
```cpp
QDBusMessage msg = QDBusMessage::createMethodCall(
    "com.lomiri.Postal",
    "/com/lomiri/Postal/pushnotification",
    "com.lomiri.Postal",
    "Post"
);
msg << "pushnotification.surajyadav_pushnotification"
    << jsonNotificationString;
bus.asyncCall(msg);
```

**Notification JSON:**
```json
{
    "notification": {
        "card": {
            "summary": "Alice",
            "body": "Hey!",
            "icon": "/path/to/avatar.jpg",
            "popup": true,
            "persist": true,
            "vibrate": true,
            "sound": true
        },
        "tag": "chat_123456"
    }
}
```

---

## Data Flow Diagram

```
Input JSON                    Processing              Output
┌────────────────────┐      ┌──────────────────┐    ┌──────────────────┐
│ {                 │      │ Push Helper      │    │ Postal Service  │
│  message: {       │  →   │ ┌──────────────┐ │ →  │ ┌────────────────┤
│    loc_key: "..." │      │ │ Parse JSON   │ │    │ │ Post()         │
│    loc_args: []   │      │ │ Format text  │ │    │ │ SetCounter()   │
│    badge: 1       │      │ │ Get avatar   │ │    │ │                │
│    custom: {}     │      │ │ Update DB    │ │    │ │ D-Bus calls    │
│  }                │      │ └──────────────┘ │    │ └────────────────┤
└────────────────────┘      └──────────────────┘    └──────────────────┘
                                    ↓
                            /tmp/message.out.json
                            (Success indicator)
```

---

## Error Scenarios

| Step | Fails | Result |
|------|-------|--------|
| Server → Cloud | Network error | No request sent |
| Cloud → Device | Device offline | Message queued 24h |
| Device → Helper | Helper crashes | No notification |
| Helper → Postal | D-Bus error | Notification not shown |
| Postal → UI | Settings disabled | No popup/badge |

---

## Testing

### Test Python Server

```bash
python3 server-example.py \
    --app-id pushnotification.surajyadav_pushnotification \
    --token YOUR_TOKEN \
    --auth YOUR_AUTH \
    --message "Test" \
    --sender "Tester"
```

### Test Push Helper Directly

```bash
# Create test input
echo '{
    "message": {
        "loc_key": "MESSAGE_TEXT",
        "loc_args": ["Alice", "Test!"],
        "badge": 1,
        "custom": {"from_id": "999"}
    }
}' > /tmp/test.json

# Run helper
/opt/click.ubuntu.com/.../push/push /tmp/test.json /tmp/out.json
```

### Test D-Bus Directly

```bash
dbus-send --session \
    /com/lomiri/Postal/pushnotification_surajyadav \
    com.lomiri.Postal.Post \
    string:"pushnotification.surajyadav_pushnotification" \
    string:'{"notification":{"card":{"summary":"Test"}}}'
```

---

## Common Questions

**Q: How long does notification take to arrive?**
A: 1-5 seconds from server to device display

**Q: What if device is offline?**
A: Message stored for 24 hours, delivered when device comes online

**Q: How does deep linking work?**
A: Custom data in message contains chat ID, app opens that chat on tap

**Q: Where are avatars stored?**
A: Local AuxDB database maps chat ID → avatar path

**Q: Can notifications be edited after sent?**
A: No, but can be cleared with ClearPersistent D-Bus call

**Q: Why D-Bus instead of direct file I/O?**
A: D-Bus is standard Ubuntu/Lomiri IPC protocol, async, non-blocking

**Q: What's loc_key for?**
A: Localization - allows translating notifications without code change

---

## Architecture Summary

```
┌──────────────────────────────────────────────────────────────┐
│ Your App (QML)                                               │
│ • Registers with Push Service                                │
│ • Gets device token                                          │
│ • Stores token in UI for you to see                          │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ Your Backend Server (Python)                                 │
│ • Receives device token from app                             │
│ • Stores tokens in database                                  │
│ • Sends HTTP POST to Lomiri Push Service when needed         │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ Lomiri Push Service (Cloud)                                  │
│ • Routes messages to devices                                 │
│ • Handles offline delivery & retries                         │
│ • Manages message queues                                     │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ Ubuntu Touch Device                                          │
│                                                              │
│ ┌─────────────────────────────────────────────────────────┐  │
│ │ Push Framework                                          │  │
│ │ • Receives message from cloud                           │  │
│ │ • Executes push-helper binary                           │  │
│ └─────────────────────────────────────────────────────────┘  │
│                       ↓                                      │
│ ┌─────────────────────────────────────────────────────────┐  │
│ │ Push Helper (C++)                                       │  │
│ │ • Reads input JSON                                      │  │
│ │ • Processes message (format, avatar, etc.)             │  │
│ │ • Updates local database                               │  │
│ │ • Posts to Postal service via D-Bus                    │  │
│ └─────────────────────────────────────────────────────────┘  │
│                       ↓                                      │
│ ┌─────────────────────────────────────────────────────────┐  │
│ │ Postal Service (D-Bus)                                  │  │
│ │ • Receives D-Bus Post call                              │  │
│ │ • Updates notification panel                            │  │
│ │ • Plays sound, vibration                                │  │
│ │ • Updates badge counter                                 │  │
│ └─────────────────────────────────────────────────────────┘  │
│                       ↓                                      │
│ ┌─────────────────────────────────────────────────────────┐  │
│ │ Lomiri Shell (UI)                                       │  │
│ │ • Shows popup banner                                    │  │
│ │ • Displays in notification center                       │  │
│ │ • Updates app badge                                     │  │
│ └─────────────────────────────────────────────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

That's it! Your push notification system is a beautiful orchestration of server, cloud service, device framework, and local services working together to deliver messages reliably and instantly.
