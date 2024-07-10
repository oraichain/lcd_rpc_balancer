FROM openresty/openresty:alpine

WORKDIR /workspace

RUN apk update && apk add --no-cache bash busybox-suid goaccess curl net-tools

RUN apk add perl curl && opm get ledgetech/lua-resty-http bungle/lua-resty-template

COPY ./conf.d /etc/nginx/conf.d

COPY ./lib /workspace/lib

COPY ./www /var/www

EXPOSE 80

RUN chmod +x /etc/nginx/conf.d/job.sh

# Add a cron job to run the bash script every minute (for example)
RUN echo "* * * * * /etc/nginx/conf.d/job.sh >> /var/log/cron.log 2>&1" > /etc/crontabs/root

# Create the log file to be able to run tail
RUN touch /var/log/cron.log /var/log/access.log

RUN goaccess /var/log/access.log -o /var/www/templates/index.html --real-time-html --ws-url=ws://3.134.19.98:80/_arws/  --date-format='%d/%b/%Y' --time-format='%T' --log-format=COMBINED --daemonize

# Ensure nginx runs in the foreground and start cron in the background
CMD crond && nginx -g 'daemon off;'
