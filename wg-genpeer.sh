#!/bin/sh

# Set vars
ip="10.13.13" #Root IP Address. Only include first 3 segments, the final one is sorted in exec.
ext_ip="$SERVERURL" #URL/IP for the connection to wireguard server
port="$SERVERPORT" #Port for the wireguard server
al_ip="$ip.0/24,192.168.0.0/24" #AllowdIP (Applied if using split tunnel)
dns="$ip.1" #Comma seperated list
svrkeypub=$(cat "/config/server/publickey-server") #Location of server public key
svrkeypvt=$(cat "/config/server/privatekey-server") #Location of server private key
wg_clients_dir="$HOME/config/" #Location to place conf files for qr scanning at a later date
listenport="51820"

# Collect device configs
read -p "Peer name: " p_name;
read -p "Peer address (3 would be $ip.3/32): " p_ip;
read -p "Split tunnel? (y/n): " split;

dir=$(pwd);
mkdir "$p_name"
cd "$p_name"

# Generate keys using colleceted info
wg genkey | tee $p_name.key | wg pubkey > $p_name.key.pub;
wg genpsk > presharedkey-$p_name

# Keys as vars
keypvt=$(cat $p_name.key);
 #echo "Pvt key: $keypvt"; #For troubleshooting
keypub=$(cat $p_name.key.pub);
keypsk=$(cat presharedkey-$p_name)
 #echo "Pub key: $keypub"; #For troubleshooting
 #echo "Pub key: $svrkeypub"; #For troubleshooting

# Sort tunnel type settings
case $split in
y)
	al_ip_fin="$al_ip"
	;;
n)
	al_ip_fin="0.0.0.0/0"
	;;
esac

#Generate conf
echo "[Interface]
Address = $ip.$p_ip
PrivateKey = $keypvt
ListenPort = $listenport
DNS = $dns

[Peer]
PublicKey = $svrkeypub
PresharedKey = $keypsk
Endpoint = $ext_ip:$port
AllowedIPs = $al_ip_fin" >> "$p_name.conf";

cd "$dir"

# Append peer to wg0.conf
echo "[Peer]
# $p_name
PublicKey = $keypub
PresharedKey = $keypsk
AllowedIPs = $ip.$p_ip/32
PersistentKeepalive = 25" >> "wg0.conf";

# Generate QR
 #echo ""
 #qrencode -t ansiutf8 < "$p_name.conf";

# Print data for wireguard on router
echo ""
echo "Information for the WireGuard peer interface:"
echo "- Description: $p_name"
echo "- Public Key: $keypub"
echo "- Allowed IPs: $ip.$p_ip/32"
