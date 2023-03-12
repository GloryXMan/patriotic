#!/bin/bash

# Find the line containing "port" in /usr/local/etc/xray/config.json
line_number=$(grep -n '"port": [1-9][0-9]*,' /usr/local/etc/xray/config.json | cut -d ':' -f 1)

# Extract the port number from the line
numbers=$(sed -n "${line_number}s/.*\"port\": \([1-9][0-9]*\),/\1/p" /usr/local/etc/xray/config.json)

# Generate a random port number between 10000 and 65000
while true
do
  Num=$((10000 + RANDOM % 55000))
  if [ $Num != $numbers ]
  then
    break
  fi
done

# Replace the old port number with the new one
sed -i "${line_number}s/${numbers}/${Num}/" /usr/local/etc/xray/config.json

# Restart xray and check if it is running
if systemctl restart xray && systemctl is-active --quiet xray
then
  echo "Xray has been restarted with port ${Num} [old port: ${numbers}]"
  rm -f change_xray_port.sh
else
  echo "Xray restart failed"
  echo "Please execute 'systemctl status xray' command to check the reason of service start failure."
fi
