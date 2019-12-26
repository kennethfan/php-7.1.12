FROM kennethfan/centos7.7:v1
COPY libmcrypt-2.5.8.tar.gz /usr/local/src/
COPY php-7.1.12.tar.gz /usr/local/src/
COPY phpredis-5.1.1.zip /usr/local/src/
COPY build.sh /usr/local/src/
RUN  cd /usr/local/src && sh build.sh && rm -rf /usr/local/src/

EXPOSE 9000
CMD ["/usr/local/php/sbin/php-fpm", "-c", "/usr/local/php/etc/php.ini", "-y", "/usr/local/php/etc/php-fpm.conf" ]
