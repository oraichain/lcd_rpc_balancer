## How to start

```bash
docker-compose up -d
docker-compose exec ingress ash
# install requirements
apk add perl curl && opm get ledgetech/lua-resty-http bungle/lua-resty-template

apk add goaccess

wget https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb
wget https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb
wget https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb

goaccess /var/log/nginx/access.log -o /var/www/templates/index.html --log-format='{ "timestamp": "%d:%t %^", "remote_addr": "%h", "body_bytes_sent": %b, "request_time": %T, "response_status": %s, "request": "%r", "request_method": "%m", "host": "%v","upstream_addr": "%^","http_x_forwarded_for": "%^","http_referrer": "%R", "http_user_agent": "%u", "http_version": "%H", "nginx_access": "%^" }' --date-format='%d/%b/%Y' --time-format='%T'  --real-time-html --daemonize --ws-url=ws://120.0.0.1:80/_arws/ --geoip-database=/etc/goaccess/GeoLite2-City.mmdb

# start nginx
nginx
```