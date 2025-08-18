#!/bin/bash

# Debug script for checking auxdb database state

echo "=== Push Notification Database Debug ==="

# Find the database file (it will be in app data directory when installed)
DB_PATH="$HOME/.local/share/pushnotification.surajyadav/auxdb/auxdb.sqlite"

if [ -f "$DB_PATH" ]; then
    echo "Database found at: $DB_PATH"
    echo ""
    
    echo "Database schema:"
    sqlite3 "$DB_PATH" ".schema"
    echo ""
    
    echo "Chat list map contents:"
    sqlite3 "$DB_PATH" "SELECT * FROM chatlist_map;"
    echo ""
    
    echo "Total unread count:"
    sqlite3 "$DB_PATH" "SELECT SUM(unread_messages) FROM chatlist_map;"
    echo ""
    
    echo "Database version:"
    sqlite3 "$DB_PATH" "PRAGMA user_version;"
    
else
    echo "Database not found at: $DB_PATH"
    echo "The app needs to be run at least once to create the database."
    echo ""
    echo "Alternative locations to check:"
    echo "- /opt/click.ubuntu.com/pushnotification.surajyadav/current/.local/share/"
    echo "- ~/.cache/pushnotification.surajyadav/"
fi

echo ""
echo "=== Debug Complete ==="
