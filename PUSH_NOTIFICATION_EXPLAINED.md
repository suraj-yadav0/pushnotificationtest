# Push Notification System - Complete Technical Explanation

This document provides an in-depth technical explanation of how your Lomiri push notification system works end-to-end.

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Component Breakdown](#component-breakdown)
3. [Complete Message Flow](#complete-message-flow)
4. [Key Technologies](#key-technologies)
5. [Implementation Details](#implementation-details)
6. [Error Handling](#error-handling)

---

## System Architecture

Your push notification system consists of **6 major layers**:

```
┌─────────────────────────────────────────────┐
│ LAYER 1: External Server                    │
│ (Python script sends HTTP POST)             │
└──────────────┬──────────────────────────────┘
               │ HTTP/HTTPS
               ▼
┌─────────────────────────────────────────────┐
│ LAYER 2: Lomiri Push Service                │
│ (push.lomiri.com - cloud service)           │
└──────────────┬──────────────────────────────┘
               │ Network delivery
               ▼
┌─────────────────────────────────────────────┐
│ LAYER 3: Device Framework                   │
│ (Ubuntu Touch OS receives message)          │
└──────────────┬──────────────────────────────┘
               │ Trigger push-helper binary
               ▼
┌─────────────────────────────────────────────┐
│ LAYER 4: Push Helper (C++)                  │
│ (pushhelper.cpp processes message)          │
└──────────────┬──────────────────────────────┘
               │ Parse JSON, format message
               ▼
┌─────────────────────────────────────────────┐
│ LAYER 5: Postal Service (D-Bus)             │
│ (com.lomiri.Postal - system service)        │
└──────────────┬──────────────────────────────┘
               │ Post notification
               ▼
┌─────────────────────────────────────────────┐
│ LAYER 6: System UI                          │
│ (User sees notification in panel)           │
└─────────────────────────────────────────────┘
```

---

## Component Breakdown

### Layer 1: External Server (Your Backend)

**File:** `server-example.py`

**Responsibility:** Send push notifications to device tokens

**How it works:**

```python
# 1. Create payload
payload = {
    "appid": "pushnotification.surajyadav_pushnotification",
    "token": device_token,  # From app registration
    "expire_on": expire_time.isoformat() + "Z",  # Expiry time
    "data": {
        "message": {
            "loc_key": "MESSAGE_TEXT",  # Notification type
            "loc_args": ["Alice", "Hey!"],  # Notification text
            "badge": 1,  # Unread count
            "custom": {"from_id": "123456"}  # Deep link data
        }
    }
}

# 2. Send HTTP POST to Lomiri Push Service
response = requests.post("https://push.lomiri.com/notify", 
                        json=payload,
                        headers={"Authorization": f"Bearer {token}"})

# 3. Push service returns status
# 200 = Success, message queued for delivery
# 4xx/5xx = Error, message not sent
```

**Key Fields:**

| Field | Purpose | Example |
|-------|---------|---------|
| `appid` | Target app ID | `pushnotification.surajyadav_pushnotification` |
| `token` | Device token | `abc123xyz...` (64+ char string) |
| `expire_on` | When to stop trying | `2025-11-11T10:30:00Z` |
| `loc_key` | Message type | `MESSAGE_TEXT`, `MESSAGE_PHOTO` |
| `loc_args` | Localization args | `["Alice", "Hey there!"]` |
| `badge` | Unread count | `1`, `5`, `10` |
| `custom` | App-specific data | `{"from_id": "123456"}` |

---

### Layer 2: Lomiri Push Service (Cloud)

**URL:** `push.lomiri.com`

**Responsibility:** Route messages to device tokens

**How it works:**

1. **Receives** HTTP POST from your server
2. **Validates**:
   - App ID is registered
   - Auth token is valid
   - Device token format is correct
3. **Looks up** device token in database
4. **Routes** message to device network address
5. **Persists** message if device is offline
6. **Retries** periodically until delivery or expiry

**Network path:**

```
Your Server → Internet → Lomiri Infrastructure → Device Network
```

---

### Layer 3: Device Framework (Ubuntu Touch OS)

**Responsibility:** Receive notification from push service

**How it works:**

1. **Receives** incoming message from Lomiri Push Service
2. **Checks** manifest.json for `push` hook
3. **Finds** push helper binary location
4. **Executes** push helper with message data:

```bash
/opt/click.ubuntu.com/pushnotification.surajyadav/1.0.0/push/push \
    /tmp/message.in.json \
    /tmp/message.out.json
```

**Configuration:**

In `manifest.json.in`:

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

In `push/push-helper.json`:

```json
{
    "exec": "push"
}
```

---

### Layer 4: Push Helper Binary (C++)

**Files:**
- `push/push.cpp` - Entry point
- `push/pushhelper.cpp` - Core logic

**Responsibility:** Process message and post to Postal service

**Step-by-step process:**

#### Step 1: Parse Command Line Arguments

```cpp
int main(int argc, char *argv[])
{
    // argc = 3
    // argv[0] = program name
    // argv[1] = input JSON file (/tmp/message.in.json)
    // argv[2] = output JSON file (/tmp/message.out.json)
    
    PushHelper helper(appId, inputFile, outputFile, &app);
    helper.process();
}
```

#### Step 2: Read Input JSON

```cpp
QJsonObject PushHelper::readPushMessage(const QString &filename)
{
    // Read /tmp/message.in.json
    QFile file(filename);
    file.open(QIODevice::ReadOnly);
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    return doc.object();
}

// Result:
// {
//     "message": {
//         "loc_key": "MESSAGE_TEXT",
//         "loc_args": ["Alice", "Hey there!"],
//         "badge": 1,
//         "custom": {"from_id": "123456"}
//     }
// }
```

#### Step 3: Extract Message Fields

```cpp
QJsonObject message = pushMessage["message"].toObject();

QString locKey = message["loc_key"].toString();
// "MESSAGE_TEXT"

QJsonArray locArgs = message["loc_args"].toArray();
// ["Alice", "Hey there!"]

int badge = message["badge"].toInt();
// 1

QJsonObject custom = message["custom"].toObject();
// {"from_id": "123456"}
```

#### Step 4: Extract Chat ID

```cpp
qint64 PushHelper::extractChatId(const QJsonObject &custom)
{
    // Look for chat ID in custom data
    // Can be named "from_id", "chat_id", etc.
    qint64 chatId = custom.value("from_id", 0).toVariant().toLongLong();
    // Example: 123456
    return chatId;
}
```

#### Step 5: Get Sender Name

```cpp
QString summary;
if (locArgs.size() > 0)
{
    summary = locArgs[0].toString();  // "Alice"
}
else
{
    summary = "Push Notification";
}
```

#### Step 6: Format Message Body

```cpp
QString PushHelper::formatNotificationMessage(
    const QString &locKey, 
    const QJsonArray &locArgs)
{
    // locKey tells us message type
    // locArgs contains template parameters
    
    if (locKey == "MESSAGE_TEXT")
    {
        // Format: "{sender}: {message}"
        return QString("%1: %2")
            .arg(locArgs[0].toString())  // Alice
            .arg(locArgs[1].toString()); // Hey there!
        // Returns: "Alice: Hey there!"
    }
    else if (locKey == "MESSAGE_PHOTO")
    {
        return QString("%1 sent a photo")
            .arg(locArgs[0].toString());
        // Returns: "Alice sent a photo"
    }
    else if (locKey == "CHAT_MESSAGE_TEXT")
    {
        return QString("%1 in %2: %3")
            .arg(locArgs[0].toString())  // sender
            .arg(locArgs[1].toString())  // group name
            .arg(locArgs[2].toString()); // message
        // Returns: "Alice in Friends: Hey!"
    }
    // ... more types
}
```

#### Step 7: Get Avatar from Database

```cpp
QString avatar = m_auxdb.getAvatarMapTable()
    ->getAvatarPathbyId(chatId);
// Example: "/home/phablet/.local/share/avatar/123456.jpg"
// Or: "notification" (default)
```

The **AuxDB** (Auxiliary Database) is a local SQLite database that stores:
- Chat ID → Avatar image path mapping
- Chat ID → Unread message count
- Other per-conversation metadata

#### Step 8: Update Badge Counter

```cpp
// Update local database
m_auxdb.getAvatarMapTable()->setUnreadMapEntry(chatId, badge);
// Now: chatId=123456, unreadCount=1

// Get total unread across all chats
qint32 totalCount = m_auxdb.getAvatarMapTable()->getTotalUnread();
// If 3 other chats also have unread: totalCount=4

// Update system badge (shows on app icon)
m_postalClient->setCount(totalCount);
// System shows [📱⁴] with red badge "4"
```

#### Step 9a: Send Transient Popup

```cpp
// Transient notification (appears as popup banner, disappears after 5 sec)
m_notificationClient->notify(
    summary,    // "Alice"
    body,       // "Alice: Hey there!"
    avatar      // "/path/to/avatar.jpg"
);
```

#### Step 9b: Send Persistent Notification

```cpp
void PostalClient::postNotification(
    const QString &tag,      // "chat_123456"
    const QString &summary,  // "Alice"
    const QString &body,     // "Hey there!"
    const QString &icon)     // "/path/to/avatar.jpg"
{
    // Build JSON for Postal service
    QJsonObject card;
    card["summary"] = "Alice";          // Title
    card["body"] = "Hey there!";        // Content
    card["icon"] = "/path/to/avatar";   // Icon/avatar
    card["popup"] = true;               // Show as popup
    card["persist"] = true;             // Stay in panel
    card["vibrate"] = true;             // Haptic feedback
    card["sound"] = true;               // Audio feedback
    
    QJsonObject notification;
    notification["card"] = card;
    notification["tag"] = "chat_123456"; // Unique ID
    
    // Convert to JSON string
    QJsonDocument doc(notification);
    QString jsonStr = QString::fromUtf8(
        doc.toJson(QJsonDocument::Compact)
    );
    
    // Send to Postal service via D-Bus
    post(jsonStr);
}
```

#### Step 10: Write Output File

```cpp
void PushHelper::writeOutputFile(
    const QString &summary,
    const QString &body,
    const QString &avatar,
    const QString &tag,
    qint32 totalCount)
{
    // Ubuntu Touch protocol requires output file
    // This tells the system the notification was processed
    
    QJsonObject result;
    result["notification"]["summary"] = summary;
    result["notification"]["body"] = body;
    result["notification"]["tag"] = tag;
    result["notification"]["avatar"] = avatar;
    result["notification"]["badge"] = totalCount;
    
    QFile outFile(mOutfile);
    outFile.open(QIODevice::WriteOnly);
    outFile.write(QJsonDocument(result).toJson());
    outFile.close();
}

// File: /tmp/message.out.json
// Content:
// {
//     "notification": {
//         "summary": "Alice",
//         "body": "Hey there!",
//         "tag": "chat_123456",
//         "avatar": "/path/to/avatar.jpg",
//         "badge": 1
//     }
// }
```

---

### Layer 5: Postal Service (D-Bus)

**Service:** `com.lomiri.Postal`

**Object Path:** `/com/lomiri/Postal/pushnotification_surajyadav`

**Responsibility:** Post notification to system and manage app badge

**How it works:**

#### D-Bus Method Call 1: Post Notification

```cpp
void PostalClient::post(const QString &jsonMessage)
{
    QDBusConnection bus = QDBusConnection::sessionBus();
    
    // Create D-Bus method call
    QDBusMessage msg = QDBusMessage::createMethodCall(
        "com.lomiri.Postal",                    // Service
        "/com/lomiri/Postal/pushnotification",  // Object path
        "com.lomiri.Postal",                    // Interface
        "Post"                                  // Method name
    );
    
    // Add parameters
    msg << "pushnotification.surajyadav_pushnotification"  // App ID
        << jsonMessage;  // Notification JSON
    
    // Send asynchronously
    QDBusPendingCall call = bus.asyncCall(msg);
    
    // When response arrives:
    // ✓ Postal service received the notification
    // ✓ It will display it in the system panel
    // ✓ It will play sound and vibration
    // ✓ It will show the icon/avatar
}
```

**D-Bus Parameters:**

| Parameter | Type | Example |
|-----------|------|---------|
| App ID | String | `pushnotification.surajyadav_pushnotification` |
| Message | String | JSON (see below) |

**Message JSON Structure:**

```json
{
    "notification": {
        "card": {
            "summary": "Alice",
            "body": "Hey there!",
            "icon": "file:///path/to/avatar.jpg",
            "popup": true,
            "persist": true,
            "vibrate": true,
            "sound": true,
            "actions": ["pushnotification://chat/123456"]
        },
        "tag": "chat_123456"
    }
}
```

#### D-Bus Method Call 2: Set Badge Counter

```cpp
void PostalClient::setCount(int count)
{
    QDBusConnection bus = QDBusConnection::sessionBus();
    
    // Create D-Bus method call
    QDBusMessage msg = QDBusMessage::createMethodCall(
        "com.lomiri.Postal",                    // Service
        "/com/lomiri/Postal/pushnotification",  // Object path
        "com.lomiri.Postal",                    // Interface
        "SetCounter"                            // Method name
    );
    
    // Add parameters
    msg << "pushnotification.surajyadav_pushnotification"  // App ID
        << count                    // Badge number (1, 2, 3...)
        << (count != 0);            // Visible flag (true if count > 0)
    
    // Send asynchronously
    bus.asyncCall(msg);
    
    // Result:
    // ✓ App icon shows badge number
    // ✓ System knows how many unread messages
    // ✓ Badge disappears when count = 0
}
```

---

### Layer 6: System UI

**What happens in Lomiri Shell:**

1. **Postal Service** receives notification via D-Bus
2. **Creates** popup banner at top of screen:
   ```
   ┌──────────────────────────────────┐
   │ 🔔 Alice                         │
   │ Hey there!                       │
   │ [5 seconds, then disappears]     │
   └──────────────────────────────────┘
   ```

3. **Adds** persistent notification to panel:
   ```
   Notification Center
   ┌──────────────────────────────┐
   │ Today                        │
   │ ┌────────────────────────────┤
   │ │ 👤 Alice                  │
   │ │ Hey there!                │
   │ │ [Tap to open chat]        │
   │ └────────────────────────────┤
   ```

4. **Updates** app badge on home screen:
   ```
   [📱¹]  ← Shows "1" unread notification
   ```

5. **Plays** system notification sound
6. **Vibrates** device (haptic feedback)

---

## Complete Message Flow

### End-to-End Timeline

```
Time 0s:    Your Server
            └─ Sends HTTP POST to push.lomiri.com
            
Time 0.5s:  Lomiri Push Service
            └─ Validates & routes message to device
            
Time 1s:    Ubuntu Touch Device
            └─ Receives message from network
            └─ Framework triggers push-helper
            
Time 1.1s:  Push Helper Binary
            ├─ Reads input JSON file
            ├─ Parses message fields
            ├─ Looks up avatar in AuxDB
            ├─ Formats notification text
            ├─ Updates badge counter in AuxDB
            └─ Sends D-Bus call to Postal service
            
Time 1.2s:  Postal Service
            ├─ Receives D-Bus Post call
            ├─ Creates popup notification banner
            ├─ Adds persistent notification to panel
            ├─ Plays system sound
            └─ Vibrates device
            
Time 1.3s:  System UI Updates
            ├─ Popup appears at top
            ├─ Notification center shows message
            ├─ App icon shows badge
            └─ User sees notification
            
Time 2-6s:  Popup visible (fades after 5 seconds)

Time 6+s:   Notification stays in panel until:
            ├─ User dismisses it
            ├─ User taps it (opens chat)
            └─ Push helper clears it
```

---

## Key Technologies

### 1. JSON Format

Messages are JSON because:
- **Language-agnostic**: C++, Python, QML can all parse it
- **Structured**: Supports nested data
- **Human-readable**: Easy to debug
- **Standard**: Used throughout Ubuntu Touch

### 2. D-Bus

D-Bus is used because:
- **Inter-process communication**: Different processes on same machine
- **Standard protocol**: All Ubuntu services use it
- **Asynchronous**: Non-blocking calls
- **Service-oriented**: Apps discover services dynamically

D-Bus flow:
```
Push Helper Process
    ↓ (creates QDBusMessage)
DBus Daemon
    ↓ (routes message)
Postal Service Process
    ↓ (receives call)
Executes SetCounter and Post methods
    ↓ (modifies system state)
Notification Panel & App Badge Updated
```

### 3. File I/O

Push helper uses files because:
- **Protocol requirement**: Ubuntu Touch expects input/output files
- **Persistence**: Message data survives process restart
- **Debugging**: Can inspect JSON files manually

File flow:
```
Lomiri Framework
    ↓ (writes message)
/tmp/message.in.json
    ↓ (push helper reads)
Push Helper Process
    ↓ (processes & writes)
/tmp/message.out.json
    ↓ (framework reads)
Framework logs success/failure
```

---

## Implementation Details

### AuxDB (Auxiliary Database)

Local SQLite database storing per-chat data:

**Tables:**

1. **AvatarMapTable**: Chat ID ↔ Avatar path

```sql
CREATE TABLE avatar_map (
    chat_id INTEGER PRIMARY KEY,
    avatar_path TEXT,
    unread_count INTEGER
);

-- Example rows:
-- | chat_id | avatar_path              | unread_count |
-- | 123456  | /path/to/alice.jpg      | 1            |
-- | 789012  | /path/to/bob.jpg        | 0            |
-- | 345678  | /path/to/group.jpg      | 2            |
```

**Usage in push helper:**

```cpp
// Get avatar for chat
QString avatar = m_auxdb.getAvatarMapTable()
    ->getAvatarPathbyId(chatId);

// Update unread count
m_auxdb.getAvatarMapTable()
    ->setUnreadMapEntry(chatId, badge);

// Get total unread
qint32 total = m_auxdb.getAvatarMapTable()
    ->getTotalUnread();  // Sum of all unread counts
```

### Message Types (loc_key)

Predefined notification types for localization:

```cpp
// Text message
"MESSAGE_TEXT" → "{sender}: {message}"
Example: "Alice: Hey there!"

// Photo message
"MESSAGE_PHOTO" → "{sender} sent a photo"
Example: "Bob sent a photo"

// Group message
"CHAT_MESSAGE_TEXT" → "{sender} in {group}: {message}"
Example: "Charlie in Friends: Anyone up for coffee?"

// Group invite
"CHAT_ADD_YOU" → "{sender} added you to {group}"
Example: "Dave added you to Book Club"

// Special: don't show notification
"READ_HISTORY" → (skipped)

// Special: no message body
"" (empty) → (skipped)
```

---

## Error Handling

### What happens if each step fails?

**Step 1: Server fails to POST**

```python
try:
    response = requests.post("https://push.lomiri.com/notify", ...)
except requests.RequestException as e:
    print(f"✗ Network error: {e}")
    # Message not sent
```

**Step 2: Push service rejects message**

```
HTTP 401 → Auth token invalid
HTTP 403 → App not authorized
HTTP 400 → Invalid payload
HTTP 429 → Rate limited
→ Message discarded after retries
```

**Step 3: Device offline**

```
Lomiri Push Service
    └─ Persists message in queue
    └─ Retries delivery for 24 hours
    └─ When device comes online: delivers message
    └─ When expiry time reached: discards message
```

**Step 4: Push helper crashes**

```cpp
if (!file.open(QIODevice::ReadOnly))
{
    qWarning() << "Cannot read input file";
    Q_EMIT done();  // Exit gracefully
    // Output file not created
    // Framework logs failure
}
```

**Step 5: Postal service unavailable**

```cpp
if (!bus.isConnected())
{
    qWarning() << "D-Bus not connected";
    return;  // Silent failure
    // Notification not posted
}
```

**Step 6: User disabled notifications**

```
System Settings
    → Notification Center
    → [App] Notifications
    → Toggle OFF
```

When disabled:
- Postal service still receives message
- But doesn't show popup
- Still shows in notification center (unless also disabled)
- Still updates badge

---

## Testing the System

### Test 1: Python Server

```bash
python3 server-example.py \
    --app-id pushnotification.surajyadav_pushnotification \
    --token YOUR_DEVICE_TOKEN \
    --auth YOUR_API_TOKEN \
    --type text \
    --sender "Test Server" \
    --message "Hello world!" \
    --chat-id 123456
```

**What to check:**
- ✓ HTTP response is 200
- ✓ Message appears on device in 1-5 seconds
- ✓ Notification has correct sender and text
- ✓ Badge counter increments

### Test 2: Push Helper Directly

```bash
# On device, create test input
adb shell cat > /tmp/test.json << 'EOF'
{
    "message": {
        "loc_key": "MESSAGE_TEXT",
        "loc_args": ["Alice", "Direct test!"],
        "badge": 1,
        "custom": {"from_id": "999999"}
    }
}
EOF

# Run push helper
adb shell "export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/32011/bus && \
    /opt/click.ubuntu.com/pushnotification.surajyadav/1.0.0/push/push \
    /tmp/test.json \
    /tmp/test.out.json"

# Check output
adb shell cat /tmp/test.out.json
```

### Test 3: D-Bus Directly

```bash
# On device, send D-Bus message directly
adb shell dbus-send \
    --session \
    --print-reply \
    /com/lomiri/Postal/pushnotification_surajyadav \
    com.lomiri.Postal.Post \
    string:"pushnotification.surajyadav_pushnotification" \
    string:'{
        "notification": {
            "card": {
                "summary": "Test",
                "body": "Direct D-Bus test!",
                "popup": true,
                "persist": true
            }
        }
    }'
```

---

## Summary

Your push notification system works in 6 layers:

1. **Server** - Sends HTTP POST with message
2. **Push Service Cloud** - Routes to device
3. **Device Framework** - Triggers push-helper
4. **Push Helper C++** - Processes message, updates DB, posts via D-Bus
5. **Postal Service** - Posts to system notification panel
6. **System UI** - Shows notification to user

Each layer is independent and can fail gracefully. The entire process takes 1-2 seconds from server request to user seeing notification.

The system is designed for:
- **Reliability**: Messages queued if device offline
- **Efficiency**: Asynchronous processing, no blocking
- **Security**: App-sandboxed, permissions checked
- **User Experience**: Rich notifications with avatars, sounds, vibration
