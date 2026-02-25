FROM webgriffe/php-apache-base:latest

RUN a2enmod rewrite headers expires

COPY apache/000-default.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html