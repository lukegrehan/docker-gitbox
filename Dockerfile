# gitbox with gitlist v.1.0.1
# https://github.com/pvdlg/docker-gitbox
# Pierre Vanduynslager <pierre.denis.vanduynslager@gmail.com>

FROM debian:stretch-slim

# Setup Container
VOLUME ["/repos"]
VOLUME ["/ng-auth"]
EXPOSE 80

# Setup Environment Variables
ENV ADMIN="gitadmin"

# Setup APT
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Update, Install Prerequisites, Clean Up APT
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && \
    apt-get -y install git curl nginx-full php7.0-fpm fcgiwrap apache2-utils && \
    apt-get clean

# Setup Container User
RUN useradd -M -s /bin/false git --uid 1000

# Setup nginx php-fpm services to run as user git, group git
RUN sed -i 's/user = www-data/user = git/g' /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i 's/group = www-data/group = git/g' /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i 's/listen.owner = www-data/listen.owner = git/g' /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i 's/listen.group = www-data/listen.group = git/g' /etc/php/7.0/fpm/pool.d/www.conf

# Setup nginx fcgi services to run as user git, group git
RUN sed -i 's/FCGI_USER="www-data"/FCGI_USER="git"/g' /etc/init.d/fcgiwrap && \
    sed -i 's/FCGI_GROUP="www-data"/FCGI_GROUP="git"/g' /etc/init.d/fcgiwrap && \
    sed -i 's/FCGI_SOCKET_OWNER="www-data"/FCGI_SOCKET_OWNER="git"/g' /etc/init.d/fcgiwrap && \
    sed -i 's/FCGI_SOCKET_GROUP="www-data"/FCGI_SOCKET_GROUP="git"/g' /etc/init.d/fcgiwrap

# Install gitlist
RUN mkdir -p /var/www
RUN wget -q -O /var/www/gitlist-v1.0.1.tar.gz https://github.com/klaussilveira/gitlist/releases/download/1.0.1/gitlist-1.0.1.tar.gz
RUN tar -zxvf /var/www/gitlist*.tar.gz -C /var/www
RUN chmod -R 777 /var/www/gitlist
RUN mkdir -p /var/www/gitlist/cache
RUN chmod 777 /var/www/gitlist/cache

# Create config files for container startup and nginx
COPY nginx.conf /etc/nginx/nginx.conf
COPY git-http-backend.conf /etc/nginx/git-http-backend.conf

# Create config files for container
COPY config.ini /var/www/gitlist/config.ini
COPY repo-admin.sh /usr/local/bin/repo-admin
COPY ng-auth.sh /usr/local/bin/ng-auth
RUN chmod +x /usr/local/bin/repo-admin
RUN chmod +x /usr/local/bin/ng-auth

# Create start.sh
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Startup
CMD ["/start.sh"]
