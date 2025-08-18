#!/bin/bash

# Test script for push notification system
# This simulates incoming push notifications for testing

APP_DIR="/tmp/pushnotification-test"
INPUT_FILE="$APP_DIR/input.json"
OUTPUT_FILE="$APP_DIR/output.json"

# Create test directory
mkdir -p "$APP_DIR"

echo "=== Push Notification Test Script ==="
echo "Testing push notification processing..."

# Test case 1: Simple text message
echo "Test 1: Simple text message"
cat > "$INPUT_FILE" << 'EOF'
{
    "message": {
        "loc_key": "MESSAGE_TEXT",
        "loc_args": ["John Doe", "Hello, this is a test message!"],
        "badge": 1,
        "custom": {
            "from_id": "123456789"
        }
    }
}
EOF

echo "Input JSON:"
cat "$INPUT_FILE"
echo ""

# Run push helper (if compiled)
if [ -f "./build/all/app/push/push" ]; then
    echo "Running push helper..."
    ./build/all/app/push/push "$INPUT_FILE" "$OUTPUT_FILE"
    
    if [ -f "$OUTPUT_FILE" ]; then
        echo "Output JSON:"
        cat "$OUTPUT_FILE"
        echo ""
    else
        echo "No output file generated"
    fi
else
    echo "Push helper binary not found. Please build the project first:"
    echo "clickable build"
fi

# Test case 2: Group message
echo ""
echo "Test 2: Group message"
cat > "$INPUT_FILE" << 'EOF'
{
    "message": {
        "loc_key": "CHAT_MESSAGE_TEXT",
        "loc_args": ["Alice", "My Group Chat", "Hey everyone!"],
        "badge": 3,
        "custom": {
            "chat_id": "987654321"
        }
    }
}
EOF

echo "Input JSON:"
cat "$INPUT_FILE"
echo ""

if [ -f "./build/all/app/push/push" ]; then
    echo "Running push helper..."
    ./build/all/app/push/push "$INPUT_FILE" "$OUTPUT_FILE"
    
    if [ -f "$OUTPUT_FILE" ]; then
        echo "Output JSON:"
        cat "$OUTPUT_FILE"
        echo ""
    fi
fi

# Test case 3: Photo message
echo ""
echo "Test 3: Photo message"
cat > "$INPUT_FILE" << 'EOF'
{
    "message": {
        "loc_key": "MESSAGE_PHOTO",
        "loc_args": ["Bob"],
        "badge": 2,
        "custom": {
            "from_id": "555666777"
        }
    }
}
EOF

echo "Input JSON:"
cat "$INPUT_FILE"
echo ""

if [ -f "./build/all/app/push/push" ]; then
    echo "Running push helper..."
    ./build/all/app/push/push "$INPUT_FILE" "$OUTPUT_FILE"
    
    if [ -f "$OUTPUT_FILE" ]; then
        echo "Output JSON:"
        cat "$OUTPUT_FILE"
        echo ""
    fi
fi

echo "=== Test Complete ==="
echo ""
echo "To test with your app:"
echo "1. Build the project: clickable build"
echo "2. Install on device: clickable install"
echo "3. Run this test script to verify push helper works"
echo "4. Use a push service to send real notifications"

# Cleanup
rm -rf "$APP_DIR"
