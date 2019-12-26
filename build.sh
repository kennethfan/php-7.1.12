#!/bin/bash
#安装php-7.1.12脚本
err_echo() {
	echo -e "\033[41;37m[Error]: $1 \033[0m"
	exit 1
}

info_echo() {
	echo -e "\033[42;37m[Info]: $1 \033[0m"
}

check_file_is_exists() {
	if [ ! -f "/usr/local/src/$1" ];then
		info_echo "$1开始下载"
	fi
}

check_exit() {
	if [ $? -ne 0 ]; then
		err_echo "$1"
		exit 1
	fi
}

check_success() {
	if [ $? -eq 0 ];then
		info_echo "$1"
	fi
}

[ $(id -u) != "0" ] && err_echo "please run this script as root user." && exit 1

function init_servers() {

	info_echo "开始初始化服务器"
	yum provides '*/applydeltarpm'  
	yum install deltarpm -y

	yum update -y
	yum install epel-release -y
	if [ -f "/etc/selinux/config" ]; then
		sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
		setenforce 0
	fi

	info_echo "更换阿里源"
	yum install wget -y
	cp /etc/yum.repos.d/* /tmp
	rm -f /etc/yum.repos.d/*
	wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
	wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
	yum clean all
}

function install_package() {

	info_echo "开始安装系统必备依赖包"
	yum install ntpdate gcc gcc-c++ wget lsof lrzsz -y

	info_echo "开始安装php所需依赖包"
	yum install -y libxml2 libxml2-devel openssl openssl-devel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel readline readline-devel libxslt libxslt-devel openjpeg-devel mysql mysql-devel libicu-devel epel-release libmcrypt-devel install m4 autoconf

	info_echo "开始安装nginx所需依赖包"
	yum install -y pcre pcre-devel zlib zlib-devel
}

function download_install_package() {

	if [ ! -f "/usr/local/src/php-7.1.12.tar.gz" ];then
		info_echo "开始下载php-7.1.12.tar.gz"
		wget -P /usr/local/src http://cn2.php.net/distributions/php-7.1.12.tar.gz
		check_success "php-7.1.12.tar.gz已下载至/usr/local/src目录"
	else
		info_echo "php-7.1.12.tar.gz已存在,不需要下载"
	fi

}

function install_mcrypt() {
	if [ ! -f "/usr/local/src/libmcrypt-2.5.8.tar.gz" ]; then
		info_echo "开始下载libmcrypt-2.5.8.tar.gz"
		wget -P /usr/local/src https://sourceforge.net/projects/mcrypt/files/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz
		check_success "libmcrypt-2.5.8.tar.gz已下载至/usr/local/src目录"
	else 
		info_echo "libmcrypt-2.5.8.tar.gz已存在,不需要下载"
	fi
	cd /usr/local/src
	tar -zvxf libmcrypt-2.5.8.tar.gz
	cd libmcrypt-2.5.8
	./configure
	make && make install
}

function install_php() {

	info_echo "开始安装php-7.1.12"
	sleep 2s
	cd /usr/local/src
	tar -zvxf /usr/local/src/php-7.1.12.tar.gz
	cd /usr/local/src/php-7.1.12
	./configure --prefix=/usr/local/php \
		--with-config-file-path=/usr/local/php/etc \
		--enable-fpm \
		--with-fpm-user=nobody \
		--with-fpm-group=nobody \
		--enable-mysqlnd \
		--with-mysqli \
		--with-mysqli=mysqlnd \
		--with-pdo-mysql=mysqlnd \
		--enable-mysqlnd-compression-support \
		--with-iconv-dir \
		--with-freetype-dir \
		--with-jpeg-dir \
		--with-png-dir \
		--with-zlib \
		--with-readline \
		--with-libxml-dir \
		--enable-xml \
		--disable-rpath \
		--enable-bcmath \
		--enable-shmop \
		--enable-sysvsem \
		--enable-inline-optimization \
		--with-curl \
		--with-Core \
		--with-ctype \
		--enable-mbregex \
		--enable-mbstring \
		--enable-intl \
		--with-mcrypt \
		--with-libmbfl \
		--enable-ftp \
		--with-gd \
		--enable-gd-jis-conv \
		--enable-gd-native-ttf \
		--with-openssl \
		--enable-pcntl \
		--enable-sockets \
		--with-xmlrpc \
		--enable-zip \
		--enable-soap \
		--with-gettext \
		--enable-fileinfo \
		--enable-opcache \
		--with-pear \
		--enable-maintainer-zts \
		--without-gdbm
	check_exit "configure php-7.1.12失败"
	make && make install
	check_exit "make php-7.1.12失败"

	info_echo "开始配置php-7.1.12"

	cp /usr/local/src/php-7.1.12/php.ini-production /usr/local/php/etc/php.ini && cd /usr/local/php/etc && cp php-fpm.conf.default php-fpm.conf
	cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf

	sed -i "s/;date.timezone =/date.timezone = Asia\/Shanghai/g" /usr/local/php/etc/php.ini
	sed -i "s#`grep max_execution_time /usr/local/php/etc/php.ini`#max_execution_time = 300#g" /usr/local/php/etc/php.ini
	sed -i "s#`grep post_max_size /usr/local/php/etc/php.ini`#post_max_size = 32M#g" /usr/local/php/etc/php.ini
	sed -i "s#`grep max_input_time\ = /usr/local/php/etc/php.ini`#max_input_time = 300#g" /usr/local/php/etc/php.ini
	sed -i "s#`grep memory_limit /usr/local/php/etc/php.ini`#memory_limit = 128M#g" /usr/local/php/etc/php.ini
	sed -i "s#`grep post_max_size /usr/local/php/etc/php.ini`#post_max_size = 32M#g" /usr/local/php/etc/php.ini
	filename=`find /usr/local/php/lib/php/extensions -name opcache.so`
	sed -i "/\[opcache\]/azend_extension=$filename" /usr/local/php/etc/php.ini
	sed -i "s/user = php-fpm/user = bumblebee/g" /usr/local/php/etc/php-fpm.d/www.conf
	sed -i "s/group = php-fpm/group = bumblebee/g" /usr/local/php/etc/php-fpm.d/www.conf
	cp /usr/local/src/php-7.1.12/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
	chmod +x /etc/init.d/php-fpm
}

function install_phpredis() {
	if [ ! -f "/usr/local/src/phpredis.5.1.1.zip" ]; then
		info_echo "开始下载phpredis-.5.1.1.zip"
		curl -v -L -o /usr/local/src/phpredis-5.1.1.zip 'https://codeload.github.com/phpredis/phpredis/zip/5.1.1'
		check_success "phpredis-5.1.1.zip已下载至/usr/local/src目录"
	else 
		info_echo "phpredis-5.1.1.zip已存在,不需要下载"
	fi
	cd /usr/local/src
	unzip phpredis-5.1.1.zip
	cd phpredis-5.1.1
	/usr/local/php/bin/phpize
	./configure --with-php-config=/usr/local/php/bin/php-config
	make && make install
	echo "[redis]" >> /usr/local/php/etc/php.ini
	echo "extension=redis.so" >> /usr/local/php/etc/php.ini
	/usr/local/php/bin/php -m | grep redis
}

function main() {

	init_servers
	install_package
	download_install_package
	install_mcrypt
	install_php
	install_phpredis
}

main
