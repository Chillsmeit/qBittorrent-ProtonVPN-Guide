# qBittorrentProtonVPN

Guide for setting up qBittorrent to use ProtonVPN using Docker:

In this guide we'll create two containers in one file, one for qBittorrent from the linuxserver.io<br>
The other one is for gluetun (vpn client) which is what we'll use for the ProtonVPN connection.<br>
Essentially, we're going to route qBittorrent traffic into the gluetun container.<br>
Since ProtonVPN assigns a random port in each VPN connection, there's a command to automatically update qbittorrent port.

First you'll need to login to https://account.protonvpn.com

Then you'll need to take note of your OpenVPN Credentials in here:

![image](https://github.com/Chillsmeit/DockerqBitProtonVPN/assets/93094077/cbf3ed2b-3a23-4034-bfdc-636ded533255)

### Create the necessary folders:
```
mkdir -p "$HOME/Docker/qbittorrent-vpn"
```
### Create a `docker-compose.yml` with:
In case you want to check the documentation about gluetun and protonvpn, check [this](https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/protonvpn.md)
```
services:
  protonvpn:
    image: docker.io/qmcgaw/gluetun:latest
    container_name: protonvpn
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    env_file: .env
    environment:
      - TZ=${TZ}
      - VPN_SERVICE_PROVIDER=${VPN_SERVICE_PROVIDER}
      - VPN_TYPE=${VPN_TYPE}
      - OPENVPN_USER=${OPENVPN_USER}
      - OPENVPN_PASSWORD=${OPENVPN_PASSWORD}
      - VPN_PORT_FORWARDING=${VPN_PORT_FORWARDING}
      - SERVER_COUNTRIES=${SERVER_COUNTRIES}
      - PORT_FORWARD_ONLY=on
      - VPN_PORT_FORWARDING_UP_COMMAND=/bin/sh -c '/usr/bin/wget -O- --retry-connrefused --post-data "json={\"listen_port\":{{PORTS}}}" http://127.0.0.1:${QBITTORRENT_WEBUI_PORT}/api/v2/app/setPreferences 2>&1'
    volumes:
      - ./vpn:/gluetun
    ports:
      - ${QBITTORRENT_WEBUI_PORT}:${QBITTORRENT_WEBUI_PORT}
    restart: unless-stopped

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    depends_on:
      - protonvpn
    env_file: .env
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - WEBUI_PORT=${QBITTORRENT_WEBUI_PORT}
    volumes:
      - ./config:/config
      - ${PATH_MEDIA}:/downloads
    network_mode: "service:protonvpn"
    restart: unless-stopped
```
### Create a `.env` file with:
```
PUID=1000
PGID=1000
TZ=Etc/UTC

# qBittorrent Settings
QBITTORRENT_WEBUI_PORT=49893
PATH_MEDIA=/path/where/qbittorrent/saves/downloads

# Gluetun Settings
VPN_SERVICE_PROVIDER=protonvpn
VPN_TYPE=openvpn
OPENVPN_USER=YOURUSER+pmp              # Use +pmp after your username
OPENVPN_PASSWORD=YOURPASSWORD
SERVER_COUNTRIES=Netherlands,Germany   # Preferred VPN server locations
VPN_PORT_FORWARDING=on                 # Enable port forwarding

# This command auto-replaces {{PORTS}} with the actual forwarded port
VPN_PORT_FORWARDING_UP_COMMAND=/bin/sh -c '/usr/bin/wget -O- --retry-connrefused --post-data "json={\"listen_port\":{{PORTS}}}" http://127.0.0.1:${QBITTORRENT_WEBUI_PORT}/api/v2/app/setPreferences 2>&1'
```
### Download latest VueTorrent Theme (optional)
```
curl -s https://api.github.com/repos/VueTorrent/VueTorrent/releases/latest | jq -r '.assets[] | select(.name | endswith(".zip")) | .browser_download_url' | xargs -I{} sh -c 'curl -L -o /tmp/vuetorrent.zip {}
unzip -o /tmp/vuetorrent.zip -d $HOME/Docker/qbittorrent-vpn/config
rm /tmp/vuetorrent.zip'
```
- **Don't forget to set the theme in qbittorrent web UI afterwards**
- Options -> Web UI -> Use alternative Web UI -> `/config/vuetorrent`

### Start the containers with:
```
docker-compose -f "$HOME/Docker/qbittorrent-vpn/docker-compose.yml" up -d
```
Or in case you have docker compose V2:
```
docker compose -f "$HOME/Docker/qbittorrent-vpn/docker-compose.yml" up -d
```

### Get qbittorrent temporary password with:
```
docker logs -f --tail 2000 qbittorrent
```
### Access the WebUI:
- Go to http://localhost:49893 and login with `admin` and the **temporary password.**
- **Change the temporary password** in qbittorrent -> `go to Options -> Web UI -> Authentication`
- **Optional**
  - Enable `Bypass authentication for clients on localhost`
  - In your terminal find the qbit container IP with `docker exec qbittorrent hostname -i`
  - Enable `Bypass authentication for clients in whitelisted IP subnets`
  - Put the qbit IP in the field, for example if your IP is `172.20.0.4` insert the following `172.20.0.0/24`
  - **Save**
- Restart container or pc
### Test the connection:
Open terminal in your docker container:
```
docker exec -it qbittorrent /bin/bash
```
Get information about the public IP the container is currently using:
```
curl -sS https://ipinfo.io/json
```
### Recommended settings to use with ProtonVPN and pmp for QBittorrent:

![image](https://github.com/user-attachments/assets/91555935-684a-460e-a198-394c429fb6b3)<br>
<br>
You can enable DHT if you want more peers<br>
<br>

![image](https://github.com/user-attachments/assets/54b89528-b0a3-45e7-9082-36199d2ef3bf)
