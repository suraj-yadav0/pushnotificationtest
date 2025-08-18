#!/usr/bin/env python3
"""
Sample server script for sending push notifications to Ubuntu Touch devices
using the push notification system.

This script demonstrates how to integrate with Ubuntu Push Service
to send notifications to your app.
"""

import json
import requests
import argparse
import time
from datetime import datetime, timedelta

class UbuntuPushClient:
    def __init__(self, app_id, auth_token=None):
        self.app_id = app_id
        self.auth_token = auth_token
        self.push_url = "https://push.ubuntu.com/notify"
        
    def send_notification(self, device_token, message_data, options=None):
        """
        Send a push notification to a specific device
        
        Args:
            device_token (str): The device-specific push token
            message_data (dict): Message data in the format expected by our push helper
            options (dict): Additional notification options
        """
        if options is None:
            options = {}
            
        # Default notification options
        expire_time = datetime.now() + timedelta(hours=24)
        
        payload = {
            "appid": self.app_id,
            "expire_on": expire_time.isoformat() + "Z",
            "token": device_token,
            "clear_pending": options.get("clear_pending", True),
            "replace_tag": options.get("replace_tag"),
            "data": message_data
        }
        
        headers = {
            "Content-Type": "application/json"
        }
        
        if self.auth_token:
            headers["Authorization"] = f"Bearer {self.auth_token}"
            
        print(f"Sending notification to device: {device_token[:10]}...")
        print(f"Message data: {json.dumps(message_data, indent=2)}")
        
        try:
            response = requests.post(self.push_url, 
                                   headers=headers, 
                                   data=json.dumps(payload),
                                   timeout=30)
            
            if response.status_code == 200:
                print("✓ Notification sent successfully!")
                return True
            else:
                print(f"✗ Error sending notification: {response.status_code}")
                print(f"Response: {response.text}")
                return False
                
        except requests.RequestException as e:
            print(f"✗ Network error: {e}")
            return False

def create_text_message(sender, message, chat_id, badge_count=1):
    """Create a text message notification"""
    return {
        "message": {
            "loc_key": "MESSAGE_TEXT",
            "loc_args": [sender, message],
            "badge": badge_count,
            "custom": {
                "from_id": str(chat_id)
            }
        }
    }

def create_photo_message(sender, chat_id, badge_count=1):
    """Create a photo message notification"""
    return {
        "message": {
            "loc_key": "MESSAGE_PHOTO",
            "loc_args": [sender],
            "badge": badge_count,
            "custom": {
                "from_id": str(chat_id)
            }
        }
    }

def create_group_message(sender, group_name, message, chat_id, badge_count=1):
    """Create a group message notification"""
    return {
        "message": {
            "loc_key": "CHAT_MESSAGE_TEXT",
            "loc_args": [sender, group_name, message],
            "badge": badge_count,
            "custom": {
                "chat_id": str(chat_id)
            }
        }
    }

def create_group_invite(sender, group_name, chat_id, badge_count=1):
    """Create a group invitation notification"""
    return {
        "message": {
            "loc_key": "CHAT_ADD_YOU",
            "loc_args": [sender, group_name],
            "badge": badge_count,
            "custom": {
                "chat_id": str(chat_id)
            }
        }
    }

def main():
    parser = argparse.ArgumentParser(description="Send Ubuntu Touch push notifications")
    parser.add_argument("--app-id", required=True, help="Application ID")
    parser.add_argument("--token", required=True, help="Device push token")
    parser.add_argument("--auth", help="Authorization token for push service")
    parser.add_argument("--type", choices=["text", "photo", "group", "invite"], 
                       default="text", help="Message type")
    parser.add_argument("--sender", default="Test Sender", help="Sender name")
    parser.add_argument("--message", default="Hello from server!", help="Message content")
    parser.add_argument("--group", help="Group name (for group messages)")
    parser.add_argument("--chat-id", type=int, default=123456789, help="Chat ID")
    parser.add_argument("--badge", type=int, default=1, help="Badge count")
    parser.add_argument("--demo", action="store_true", help="Run demo with sample messages")
    
    args = parser.parse_args()
    
    # Initialize push client
    client = UbuntuPushClient(args.app_id, args.auth)
    
    if args.demo:
        print("Running push notification demo...")
        
        # Demo messages
        messages = [
            ("Direct Message", create_text_message("Alice", "Hey there! How are you?", 123456, 1)),
            ("Photo Message", create_photo_message("Bob", 789012, 2)),
            ("Group Message", create_group_message("Charlie", "My Friends", "Anyone up for coffee?", 345678, 3)),
            ("Group Invite", create_group_invite("Dave", "Book Club", 901234, 4))
        ]
        
        for name, message_data in messages:
            print(f"\n--- Sending {name} ---")
            client.send_notification(args.token, message_data, {"replace_tag": f"demo_{int(time.time())}"})
            time.sleep(2)  # Delay between messages
            
    else:
        # Single message based on arguments
        if args.type == "text":
            message_data = create_text_message(args.sender, args.message, args.chat_id, args.badge)
        elif args.type == "photo":
            message_data = create_photo_message(args.sender, args.chat_id, args.badge)
        elif args.type == "group":
            if not args.group:
                print("Error: --group is required for group messages")
                return
            message_data = create_group_message(args.sender, args.group, args.message, args.chat_id, args.badge)
        elif args.type == "invite":
            if not args.group:
                print("Error: --group is required for group invites")
                return
            message_data = create_group_invite(args.sender, args.group, args.chat_id, args.badge)
        
        client.send_notification(args.token, message_data, {"replace_tag": f"msg_{args.chat_id}"})

if __name__ == "__main__":
    main()
