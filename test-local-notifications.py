#!/usr/bin/env python3
"""
Local notification testing tool
Run this script on your Ubuntu Touch device to test notifications
"""

import subprocess
import json
import time
import sys
import os
from datetime import datetime

# Set D-Bus session address for phablet user
os.environ['DBUS_SESSION_BUS_ADDRESS'] = 'unix:path=/run/user/32011/bus'

APP_ID = "pushnotification.surajyadav_pushnotification"
PKG_NAME = "pushnotification_2esurajyadav"

class Colors:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'

def send_notification(title, body, tag=None, icon="notification-symbolic"):
    """Send a notification using the freedesktop Notifications service"""
    
    if tag is None:
        tag = f"test-{int(time.time())}"
    
    # Clean text for display
    title_clean = title.encode('ascii', 'ignore').decode('ascii')
    body_clean = body.encode('ascii', 'ignore').decode('ascii')
    
    print(f"{Colors.YELLOW}Sending: {title}{Colors.END}")
    print(f"Message: {body}")
    print(f"Tag: {tag}")
    
    try:
        # Use org.freedesktop.Notifications for actual notification display
        result = subprocess.run([
            "gdbus", "call", "--session",
            "--dest", "org.freedesktop.Notifications",
            "--object-path", "/org/freedesktop/Notifications",
            "--method", "org.freedesktop.Notifications.Notify",
            APP_ID,  # app_name
            "0",  # replaces_id (0 = new notification)
            icon,  # app_icon
            title_clean,  # summary
            body_clean,  # body
            "[]",  # actions
            "{}",  # hints
            "5000"  # expire_timeout (5 seconds)
        ], capture_output=True, text=True, timeout=5)
        
        if result.returncode == 0:
            print(f"{Colors.GREEN}✓ Notification sent successfully!{Colors.END}\n")
            return True
        else:
            print(f"{Colors.RED}✗ Failed to send notification{Colors.END}")
            print(f"Error: {result.stderr}\n")
            return False
    except subprocess.TimeoutExpired:
        print(f"{Colors.RED}✗ Timeout sending notification{Colors.END}\n")
        return False
    except Exception as e:
        print(f"{Colors.RED}✗ Error: {e}{Colors.END}\n")
        return False

def set_badge(count):
    """Set the badge counter"""
    
    visible = "true" if count > 0 else "false"
    
    print(f"{Colors.YELLOW}Setting badge counter to: {count}{Colors.END}")
    
    try:
        result = subprocess.run([
            "gdbus", "call", "--session",
            "--dest", "com.lomiri.Postal",
            "--object-path", f"/com/lomiri/Postal/{PKG_NAME}",
            "--method", "com.lomiri.Postal.SetCounter",
            APP_ID,
            str(count),
            visible
        ], capture_output=True, text=True, timeout=5)
        
        if result.returncode == 0:
            print(f"{Colors.GREEN}✓ Badge counter updated!{Colors.END}\n")
            return True
        else:
            print(f"{Colors.RED}✗ Failed to update badge{Colors.END}\n")
            return False
    except Exception as e:
        print(f"{Colors.RED}✗ Error: {e}{Colors.END}\n")
        return False

def clear_notifications(tag=""):
    """Clear notifications"""
    
    print(f"{Colors.YELLOW}Clearing notifications...{Colors.END}")
    
    try:
        result = subprocess.run([
            "gdbus", "call", "--session",
            "--dest", "com.lomiri.Postal",
            "--object-path", f"/com/lomiri/Postal/{PKG_NAME}",
            "--method", "com.lomiri.Postal.ClearPersistent",
            APP_ID,
            tag
        ], capture_output=True, text=True, timeout=5)
        
        if result.returncode == 0:
            print(f"{Colors.GREEN}✓ Notifications cleared!{Colors.END}\n")
            return True
        else:
            print(f"{Colors.RED}✗ Failed to clear notifications{Colors.END}\n")
            return False
    except Exception as e:
        print(f"{Colors.RED}✗ Error: {e}{Colors.END}\n")
        return False

def run_tests():
    """Run all notification tests"""
    
    print(f"{Colors.BLUE}{Colors.BOLD}Running notification tests...{Colors.END}\n")
    
    tests = [
        ("Welcome", "Push notification system is working", "test-1"),
        ("Alice", "Hey there", "chat-001"),
        ("Bob", "sent you a photo", "chat-002"),
        ("Work Group", "Sarah: Meeting at 3pm tomorrow", "group-001"),
        ("System Alert", "Your app is functioning correctly", "system-001")
    ]
    
    success_count = 0
    for title, body, tag in tests:
        if send_notification(title, body, tag):
            success_count += 1
        time.sleep(1.5)  # Delay between notifications
    
    # Set badge counter
    set_badge(len(tests))
    
    print(f"{Colors.GREEN}{Colors.BOLD}✓ Test completed!{Colors.END}")
    print(f"Sent {success_count}/{len(tests)} notifications successfully")
    print(f"{Colors.BLUE}Check your notification panel!{Colors.END}\n")

def interactive_mode():
    """Interactive menu for testing"""
    
    while True:
        print(f"\n{Colors.BLUE}╔════════════════════════════════════════════╗{Colors.END}")
        print(f"{Colors.BLUE}║  Push Notification Local Testing Tool     ║{Colors.END}")
        print(f"{Colors.BLUE}╚════════════════════════════════════════════╝{Colors.END}\n")
        
        print("Choose a test:")
        print("1) Simple notification")
        print("2) Message notification")
        print("3) Photo notification")
        print("4) Group message")
        print("5) Set badge counter")
        print("6) Clear notifications")
        print("7) Run all tests")
        print("8) Custom notification")
        print("9) Exit")
        print()
        
        try:
            choice = input("Enter choice (1-9): ").strip()
            print()
            
            if choice == "1":
                send_notification("Test Notification", "This is a simple test notification", "test-simple")
                
            elif choice == "2":
                send_notification("Alice", "Hey! How are you doing today?", "chat-123456")
                
            elif choice == "3":
                send_notification("Bob", "sent you a photo", "chat-789012", "image")
                
            elif choice == "4":
                send_notification("Project Team", "Charlie: Meeting at 3pm tomorrow", "group-345678", "group")
                
            elif choice == "5":
                count = int(input("Enter badge count (0 to hide): "))
                set_badge(count)
                
            elif choice == "6":
                clear_notifications()
                set_badge(0)
                
            elif choice == "7":
                run_tests()
                
            elif choice == "8":
                title = input("Enter notification title: ")
                body = input("Enter notification message: ")
                tag = input("Enter tag (optional): ") or None
                send_notification(title, body, tag)
                
            elif choice == "9":
                print("Goodbye!")
                break
                
            else:
                print(f"{Colors.RED}Invalid choice!{Colors.END}")
                
        except KeyboardInterrupt:
            print("\n\nGoodbye!")
            break
        except Exception as e:
            print(f"{Colors.RED}Error: {e}{Colors.END}")

def main():
    """Main entry point"""
    
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == "test":
            run_tests()
        elif command == "simple":
            send_notification("Test", "Simple test notification")
        elif command == "clear":
            clear_notifications()
            set_badge(0)
        elif command == "badge":
            count = int(sys.argv[2]) if len(sys.argv) > 2 else 1
            set_badge(count)
        else:
            print(f"Usage: {sys.argv[0]} [test|simple|clear|badge]")
            print(f"Or run without arguments for interactive mode")
    else:
        interactive_mode()

if __name__ == "__main__":
    main()
