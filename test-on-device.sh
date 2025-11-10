#!/bin/bash

# This script runs ON the device to test the Postal notification system

# Test 1: Send a notification using Postal.Post
echo "=== Test 1: Sending notification via Postal.Post ===" 
gdbus call --session \
  --dest com.lomiri.Postal \
  --object-path /com/lomiri/Postal/pushnotification_2esurajyadav \
  --method com.lomiri.Postal.Post \
  'pushnotification.surajyadav_pushnotification' \
  '{"notification":{"tag":"devicetest1","card":{"summary":"Device Test","body":"Testing from device script","icon":"notification","persist":true,"popup":true}}}'

echo ""
echo "=== Test 2: Checking GetNotifications ===" 
gdbus call --session \
  --dest org.freedesktop.Notifications \
  --object-path /org/freedesktop/Notifications \
  --method org.freedesktop.Notifications.GetNotifications \
  'pushnotification.surajyadav_pushnotification'

echo ""
echo "=== Test 3: Sending via org.freedesktop.Notifications ===" 
gdbus call --session \
  --dest org.freedesktop.Notifications \
  --object-path /org/freedesktop/Notifications \
  --method org.freedesktop.Notifications.Notify \
  'pushnotification.surajyadav_pushnotification' \
  0 \
  'notification' \
  'FreeDesktop Test' \
  'This is from FreeDesktop Notifications' \
  '[]' \
  '{}' \
  5000

echo ""
echo "Done! Check notification panel."
