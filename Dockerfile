FROM openresty/openresty:alpine

RUN apk update && \
    apk add perl curl goaccess && \
    opm get ledgetech/lua-resty-http bungle/lua-resty-template

RUN wget https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb && \
    wget https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb && \
    wget https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb

WORKDIR /workspace

COPY lib /workspace/lib
COPY www /var/www

EXPOSE 80 8080

ENTRYPOINT ["nginx", "-g", "daemon off;"]
