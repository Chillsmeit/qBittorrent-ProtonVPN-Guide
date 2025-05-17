#!/bin/bash

qbit_url="http://localhost:49893"   # Change to your Web UI address
user=""                             # Leave empty to skip auth
password=""                         # Leave empty to skip auth
cookie_file="/tmp/qbit_cookies.txt" # Will only be used if you use auth

if [ -z "$1" ]; then
  echo "Usage: $0 <magnet-link>"
  exit 1
fi

magnet_link="$1"

if [[ -n "$user" && -n "$password" ]]; then

  curl -s -c "$cookie_file" -b "$cookie_file" \
    -d "username=$user&password=$password" \
    "$qbit_url/api/v2/auth/login" > /dev/null


  if ! grep -q 'SID' "$cookie_file"; then
    echo "Login failed. Check your username/password and Web UI status."
    rm -f "$cookie_file"
    exit 1
  fi

  cookie_option="-b $cookie_file"
else
  cookie_option=""
fi

curl -s $cookie_option \
  --data-urlencode "urls=$magnet_link" \
  "$qbit_url/api/v2/torrents/add"

[ -f "$cookie_file" ] && rm -f "$cookie_file"
echo -e "\e[32m\nMagnet link sent to qBittorrent ✔\e[0m"
