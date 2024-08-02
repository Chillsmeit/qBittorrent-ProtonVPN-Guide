# qBittorrentProtonVPN

Guide for setting up qBittorrent to use ProtonVPN using Docker:

In this guide we'll create two containers, one for qBittorrent from the linuxserver.io<br>
The other one is for gluetun (vpn client) which is what we'll use for the ProtonVPN connection.<br>
Essentially, we're going to route qBittorrent traffic into the gluetun container.

First you'll need to login to https://account.protonvpn.com

Then you'll need to take note of your OpenVPN Credentials in here:

![image](https://github.com/Chillsmeit/DockerqBitProtonVPN/assets/93094077/cbf3ed2b-3a23-4034-bfdc-636ded533255)

### Create the necessary folders:
```
mkdir -p "$HOME/Docker/protonvpn" && mkdir -p "$HOME/Docker/qbittorrent/config"
```
### Use cat to quickly fill in the info for the gluetun yml file:
In case you want to check the documentation about glueton and protonvpn, check [this](https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/protonvpn.md)
```
cat <<EOF > "$HOME/Docker/protonvpn/docker-compose.yml"
services:
  gluetun:
    image: qmcgaw/gluetun
    container_name: protonvpn
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    ports: # These are the qBittorrent ports, I like to use random ports and not the default ports 49152
      - 49893:49893 # This is for the qBittorrent WebUI Port
      - 6881:6881 # Listening port for TCP
      - 6881:6881/udp # Listening port for UDP
    environment:
      - VPN_SERVICE_PROVIDER=protonvpn
      - OPENVPN_USER=username # REPLACE these with your OpenVPN credentials. Use +pmp after your username to use port forwarding
      - OPENVPN_PASSWORD=password # REPLACE these with your OpenVPN credentials
      - VPN_PORT_FORWARDING=on
      - SERVER_COUNTRIES=Netherlands,Germany # The server countries we'll use. They have to be P2P
    volumes:
      - ./config:/gluetun
    restart: unless-stopped
EOF
```
### Use cat to quickly fill in the info for the qbittorrent yml file:
```
cat <<EOF > "$HOME/Docker/qbittorrent/docker-compose.yml"
services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=1000 # to find your current ID just type "id" in the terminal
      - PGID=1000 # to find your current group ID just type "id" in the terminal
      - TZ=Etc/UTC
      - WEBUI_PORT=49893 # This needs to be the exact same port we used on glueton for the WebUI
      - TORRENTING_PORT=6881
    volumes:
      - ./config:/config # this will create the config folder in the same folder as we have the yml file
      - /path/to/your/drive:/downloads # change the left part of : to your actual path where you want to store your downloads
    network_mode: "container:protonvpn" # this needs to be the exact same name as the protonvpn container we defined
    restart: unless-stopped
EOF
```
### Download latest VueTorrent Theme (optional)
```
curl -s https://api.github.com/repos/VueTorrent/VueTorrent/releases/latest | jq -r '.assets[] | select(.name | endswith(".zip")) | .browser_download_url' | xargs -I{} sh -c 'curl -L -o /tmp/vuetorrent.zip {}
unzip -o /tmp/vuetorrent.zip -d $HOME/Docker/qbittorrent/config
rm /tmp/vuetorrent.zip'
```
- **Don't forget to set the theme in qbittorrent web UI**
- Options -> Web UI -> Use alternative Web UI -> `/config/vuetorrent`
### Start the gluetun/protonvpn container:
```
docker-compose -f "$HOME/Docker/protonvpn/docker-compose.yml" up -d
```
### Start the qbittorrent container:
```
docker-compose -f "$HOME/Docker/qbittorrent/docker-compose.yml" up -d
```
### Get qbittorrent credentials with:
```
echo -n "\nUsername: admin \nPassword: " && docker logs qbittorrent 2>&1 | tac | grep -m 1 -oP 'A temporary password is provided for this session: \K\w+'
```
- **Don't forget to change the password** in qbittorrent web UI -> go to Options -> Web UI
### Access the WebUI:
- Go to http://localhost:49893
### Test the connection:
Open terminal in your docker container:
```
docker exec -it qbittorrent /bin/bash
```
Get information about the public IP the container is currently using:
```
curl -sS https://ipinfo.io/json
```
### Good settings to use with ProtonVPN and pmp for qbittorrent:

![image](https://github.com/user-attachments/assets/91555935-684a-460e-a198-394c429fb6b3)<br>
**You can enable DHT if you want more peers**<br>
![image](https://github.com/user-attachments/assets/54b89528-b0a3-45e7-9082-36199d2ef3bf)
