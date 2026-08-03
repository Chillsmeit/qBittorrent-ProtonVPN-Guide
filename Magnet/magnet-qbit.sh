#!/bin/bash

qbit_url="http://localhost:49893"   # Change to your Web UI address
user=""                             # Leave empty to skip auth
password=""                         # Leave empty to skip auth
cookie_file="/tmp/qbit_cookies.txt" # Will only be used if you use auth

# Notify via desktop popup if available, always print to terminal too
notify() {
  local urgency="$1" msg="$2"
  echo -e "$msg"
  command -v notify-send >/dev/null && notify-send -u "$urgency" "qBittorrent" "$msg"
}

if [ -z "$1" ]; then
  echo "Usage: $0 <magnet-link>"
  exit 1
fi

magnet_link="$1"

cookie_option=()
if [[ -n "$user" && -n "$password" ]]; then

  curl -s -c "$cookie_file" -b "$cookie_file" \
    -d "username=$user&password=$password" \
    "$qbit_url/api/v2/auth/login" > /dev/null

  if ! grep -q 'SID' "$cookie_file"; then
    notify critical "Login failed. Check username/password and Web UI status."
    rm -f "$cookie_file"
    exit 1
  fi

  cookie_option=(-b "$cookie_file")
fi

status=$(curl -s -o /dev/null -w "%{http_code}" "${cookie_option[@]}" \
  --data-urlencode "urls=$magnet_link" \
  "$qbit_url/api/v2/torrents/add")

[ -f "$cookie_file" ] && rm -f "$cookie_file"

if [[ "$status" == "200" ]]; then
  notify normal "Magnet link sent ✔"
elif [[ "$status" == "000" ]]; then
  notify critical "Can't reach Web UI. Is the container running?"
  exit 1
elif [[ "$status" == "403" ]]; then
  notify critical "Unauthorized. Set user/password in the script."
  exit 1
else
  notify critical "Failed to send magnet (HTTP $status)"
  exit 1
fi