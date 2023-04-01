ARG PHP_FPM_VERSION=8.1

FROM php:${PHP_FPM_VERSION}-fpm

RUN apt-get update \
    && apt-get install -y git \
    && apt-get install -y \
		libfreetype6-dev \
		libxpm-dev \
		libpng-dev \
		libicu-dev \
		libxml2-dev \
		libxslt-dev \
		libzip-dev \
		libgmp-dev \
		libcurl4-openssl-dev \
		libwebp-dev \
		libonig-dev \
		libldap2-dev \
		sqlite3 \
		libsqlite3-dev \
		libjpeg-dev \
	&& docker-php-ext-configure intl \
	&& docker-php-ext-install bcmath \
			mbstring \
			intl \
			pdo_mysql \
			soap \
			sockets \
			xsl \
			pdo \
	&& docker-php-ext-install -j$(nproc) zip

# changing host file
#RUN cat /etc/hosts >> /etc/hosts.backup \
#    && echo "dashboard.mageplaza.com:198.199.79.159" >> /etc/hosts.backup
#RUN cat /etc/hosts.backup >> /etc/hosts

RUN apt-get install wget

WORKDIR /

RUN wget http://www.ijg.org/files/jpegsrc.v9e.tar.gz
RUN tar xvfz jpegsrc.v9e.tar.gz
WORKDIR /jpeg-9e
RUN ./configure
RUN make && make install
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg=/usr/local/lib
RUN docker-php-ext-install gd

# install composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# copy entry point
COPY ./docker-entry.sh /
RUN chmod +x /docker-entry.sh

# copy auth.json
COPY ./auth.json /root/.composer/

# executing entry point
ENTRYPOINT ["bash", "/docker-entry.sh"]
WORKDIR /var/www/html
EXPOSE 9000