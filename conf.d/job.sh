#!/bin/bash
discord_url="https://discord.com/api/webhooks/1068442147210133565/-qkoMuZjGI0ipankQqnVp4QGh9yfYPdl5CoN0xirDzWlC8qk3X6NlAfweoMvFlylsOnd"
generate_post_data() {
  cat <<EOF
{
  "content": "$1"
}
EOF
}

# osmosis-1
IPS_OSMO=$(curl -s 'https://devops-tool.orai.io/node_api.php?network=osmosis-1')

# cosmoshub-4
IPS_ATOM=$(curl -s 'https://devops-tool.orai.io/node_api.php?network=cosmoshub-4')

# injecttive-1
IPS_INJ=$(curl -s 'https://devops-tool.orai.io/node_api.php?network=injective-1')

if [ -n "$IPS_OSMO" ]; then
    sed -i.bak -E "s|^([[:space:]]+local[[:space:]]+osmo_up[[:space:]]+=[[:space:]]+resty_roundrobin:new).*$|\1\(\{"$IPS_OSMO"\}\)|" /etc/nginx/conf.d/default.conf
else
    curl -s -H "Content-Type: application/json" -X POST -d "$(generate_post_data "The string OSMO is empty")" $discord_url
fi

if [ -n "$IPS_ATOM" ]; then
    sed -i.bak -E "s|^([[:space:]]+local[[:space:]]+atom_up[[:space:]]+=[[:space:]]+resty_roundrobin:new).*$|\1\(\{"$IPS_ATOM"\}\)|" /etc/nginx/conf.d/default.conf
else
    curl -s -H "Content-Type: application/json" -X POST -d "$(generate_post_data "The string ATOM is empty")" $discord_url
fi

if [ -n "$IPS_INJ" ]; then
    sed -i.bak -E "s|^([[:space:]]+local[[:space:]]+inj_up[[:space:]]+=[[:space:]]+resty_roundrobin:new).*$|\1\(\{"$IPS_INJ"\}\)|" /etc/nginx/conf.d/default.conf
else
    curl -s -H "Content-Type: application/json" -X POST -d "$(generate_post_data "The string INJ is empty")" $discord_url
fi

nginx -s reload
