FROM openresty/openresty:alpine

RUN apk update && \
    apk add perl curl goaccess && \
    opm get ledgetech/lua-resty-http bungle/lua-resty-template

WORKDIR /workspace

COPY GeoLite2-ASN.mmdb /workspace/GeoLite2-ASN.mmdb
COPY GeoLite2-City.mmdb /workspace/GeoLite2-City.mmdb
COPY GeoLite2-Country.mmdb /workspace/GeoLite2-Country.mmdb
COPY lib /workspace/lib
COPY www /var/www

EXPOSE 80 8080

ENTRYPOINT ["nginx", "-g", "daemon off;"]
