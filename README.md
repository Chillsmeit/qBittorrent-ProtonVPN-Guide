#WIP

# DockerqBitProtonVPN
Guide for setting up qBittorrent to use ProtonVPN using Docker:

In this guide we'll create two containers, one for qBittorrent from the linuxserver.io<br>
The other one is for gluetun which is what we'll use for ProtonVPN.<br>
Essentially, we're going to route qBittorrent traffic into the gluetun container.

First you'll need to login to https://account.protonvpn.com

Then you'll need to take note of your OpenVPN Credentials in here:
![image](https://github.com/Chillsmeit/DockerqBitProtonVPN/assets/93094077/cbf3ed2b-3a23-4034-bfdc-636ded533255)

I usually create a docker folder in my Home folder and create individual folders for each container, keeps things tidy.

Create the necessary folders:
```
mkdir -p "$HOME/Docker/protonvpn" && mkdir -p "$HOME/Docker/qbittorrent
```
Create the YML for gluetun:
```
touch "$HOME/Docker/protonvpn/docker-compose.yml"
```
```
cat <<EOF > "$HOME/Docker/protonvpn/docker-compose.yml"
version: "3"
services:
  gluetun:
    image: qmcgaw/gluetun
    container_name: protonvpn # I like to change the container name to the VPN I use
    cap_add:
      - NET_ADMIN
    ports: # In here we'll put the qBittorrent ports
      - 13750:13750 # This is for the qBittorrent WebUI Port
      - 7830:7830
      - 7830:7830/udp
    environment:
      - VPN_SERVICE_PROVIDER=protonvpn
      - OPENVPN_USER=youropenvpnusername
      - OPENVPN_PASSWORD=youropenvpnpassword
      - SERVER_COUNTRIES=Netherlands
    volumes:
      - ./ProtonVPN:/gluetun
    restart: unless-stopped
