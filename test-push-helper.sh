#!/bin/bash
# Test push helper directly with a sample push message

APP_ID="pushnotification.surajyadav_pushnotification"

# Create a temporary input file with push message
INFILE="/tmp/push_test_input.json"
OUTFILE="/tmp/push_test_output.json"

cat > "$INFILE" << 'EOF'
{
    "message": {
        "loc_key": "MESSAGE_TEXT",
        "loc_args": ["Alice", "Hey! This is a test message from the push helper!"],
        "badge": 1,
        "custom": {
            "from_id": "123456789"
        }
    }
}
EOF

echo "Testing push helper with sample message..."
echo "Input file: $INFILE"
echo "Output file: $OUTFILE"
echo ""

# Run the push helper directly
adb shell "/opt/click.ubuntu.com/pushnotification.surajyadav/1.0.0/push/push $INFILE $OUTFILE"

echo ""
echo "Done! Check your notification panel."
