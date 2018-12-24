#!/bin/sh

#echo "alias c='clear'" >> /etc/profile
#echo 'set -o vi' >> /etc/profile

#yum -y install tmux vim git bzip2

# config tmux
#touch ~/.tmux.conf
(
cat <<EOF
# improve colors
#set -g default-terminal 'screen-256color'
set -g default-terminal 'linux'
# act like vim
setw -g mode-keys vi
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
#bind-key -r C-h select-window -t :-
#bind-key -r C-l select-window -t :+
# 重新调整窗格的大小
bind K resizep -U 5
bind J resizep -D 5
bind-key L switch-client -l
#bind-key -n L switch-client -l
# 状态栏中的窗口列表居中
set -g status-justify centre
# 状态栏启用utf-8
#set -g status-utf8 on
#设置窗口列表颜色
#setw -g window-status-fg cyan
#setw -g window-status-bg default
#setw -g window-status-attr dim
#设置当前窗口在status bar中的颜色
setw -g window-status-current-fg white
setw -g window-status-current-bg red
setw -g window-status-current-attr bright
#开启window事件提示
setw -g monitor-activity on
set -g base-index 1
set-window-option -g pane-base-index 1
# soften status bar color from harsh green to light gray
set -g status-bg '#666666'
set -g status-fg '#aaaaaa'
# remove administrative debris (session name, hostname, time) in status bar
set -g status-left ''
set -g status-right ''
# increase scrollback lines
set -g history-limit 10000
# switch to last pane
bind-key C-a last-pane
# tmux vim clipboard
set -g focus-events on
EOF
) > ~/.tmux.conf


#
#(
#cat << EOF
#要写的文本
#EOF
#) > 目标文件
# config vim

# install mysql
type mysql > /dev/null 2>&1
if [[ $? != 0 ]];then
	if [[ ! -f "mysql57-community-release-el7-9.noarch.rpm" ]];then
		wget https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
	fi
	rpm -ivh mysql57-community-release-el7-9.noarch.rpm
	yum -y install mysql-server
fi


cd ~

phpPath=/webser/soft/php72

# install php
if [[ ! -f "${phpPath}/bin/php" ]]; then
	if [[ ! -f "./php-7.2.9.tar.bz2" ]];then
		wget http://php.net/distributions/php-7.2.9.tar.bz2
	fi
	#yum install -y gcc automake autoconf libtool gcc-c++
	#yum install -y gd zlib zlib-devel openssl openssl-devel libxml2 libxml2-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libmcrypt libmcrypt-devel curl-devel
	if [[ ! -d "./php-7.2.9" ]];then
		tar -jxf php-7.2.9.tar.bz2
	else
		if [[ ! -d "$phpPath" ]];then
			mkdir -p $phpPath
		fi
		cd php-7.2.9
		./buildconf
		./configure --prefix=/webser/soft/php72 --exec-prefix=/webser/soft/php72 --with-mysql-sock=/var/lib/mysql/mysql.sock --with-mcrypt=/usr/include --with-mhash --with-openssl --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-gd --with-iconv --with-zlib --enable-zip  --enable-inline-optimization --disable-debug --disable-rpath --enable-shared --enable-xml --enable-bcmath --enable-shmop --enable-mbregex --enable-mbstring --enable-ftp --enable-gd-native-ttf --enable-pcntl --enable-sockets --with-xmlrpc --enable-soap --without-pear --with-gettext --enable-session --with-curl --with-openssl --with-jpeg-dir --with-freetype-dir --enable-opcache --enable-fpm --with-fpm-user=www  --with-fpm-group=www --without-gdbm --enable-fileinfo --enable-sysvsem --enable-sysvshm --enable-sysvmsg --enable-pcntl --enable-maintainer-zts --enable-pthreads
		make && make install
		cp ./php.ini-development ${phpPath}/etc/php.ini
		cd ${phpPath}/etc
		cp ./php-fpm.conf.default ./php-fpm.conf
		cp ./php-fpm.d/www.conf.default ./php-fpm.d/www.conf
	fi
fi


cd ~
# install nginx + lua

type luajit > /dev/null 2>&1
if [[ $? != 0 ]];then
	wget http://luajit.org/download/LuaJIT-2.1.0-beta3.tar.gz
	tar xvf LuaJIT-2.1.0-beta3.tar.gz
	mv LuaJIT-2.1.0-beta3 LuaJIT-2.1
	cd LuaJIT-2.1
	make && make install
	cd /usr/local/bin && ln -sf luajit-2.1.0-beta3 luajit
	sed -ri '/export.*LUAJIT_(LIB|INC)/d' /etc/profile
	echo -e "\nexport LUAJIT_LIB=/usr/local/lib\n \
	export LUAJIT_INC=/usr/local/include/luajit-2.1\n \ 
	export LD_LIBRARY_PATH=\$LUAJIT_LIB:\$LD_LIBRARY_PATH" >> /etc/profile
fi

. /etc/profile
cd ~

nginxPath=/webser/soft/nginx
if [[ ! -f "$nginxPath/sbin/nginx" ]];then
	yum install gcc pcre pcre-devel gd-devel xz -y
	if [[ ! -f "./nginx-1.14.0.tar.gz" ]];then
		wget http://nginx.org/download/nginx-1.14.0.tar.gz
		if [[ ! -d "nginx-1.14.0" ]];then
			tar zxf nginx-1.14.0.tar.gz
		fi
	fi
	if [[ ! -f "./openssl-1.1.0h.tar.gz" ]];then
		wget https://www.openssl.org/source/openssl-1.1.0h.tar.gz
		if [[ ! -d "openssl-1.1.0h" ]];then
			tar zxf openssl-1.1.0h.tar.gz
		fi
	fi
	if [[ ! -f "./zlib-1.2.11.tar.gz" ]];then
		wget http://zlib.net/zlib-1.2.11.tar.gz
		if [[ ! -d "zlib-1.2.11" ]];then
			tar zxf zlib-1.2.11.tar.gz
		fi
	fi
	if [[ ! -f "./pcre-8.41.tar.gz" ]];then
		wget https://ftp.pcre.org/pub/pcre/pcre-8.41.tar.gz 
		if [[ ! -d "pcre-8.41" ]];then
			tar zxf pcre-8.41.tar.gz
		fi
	fi
	cd nginx-1.14.0/src
	if [[ ! -d "ngx_devel_kit" ]];then
		git clone https://github.com/simplresty/ngx_devel_kit.git
	fi
	if [[ ! -d "headers-more-nginx-module" ]];then
		git clone https://github.com/openresty/headers-more-nginx-module.git
	fi
	if [[ ! -d "lua-nginx-module" ]];then
		git clone https://github.com/openresty/lua-nginx-module.git
	fi
	cd ..
	make clean
	./configure --prefix=$nginxPath --with-http_ssl_module --with-pcre=../pcre-8.41 --with-zlib=../zlib-1.2.11 --with-http_realip_module --with-http_gzip_static_module --with-http_addition_module --with-http_ssl_module --with-http_v2_module --with-http_sub_module --with-http_image_filter_module --add-module=./src/ngx_devel_kit --add-module=./src/headers-more-nginx-module --add-module=./src/lua-nginx-module --with-pcre-jit --with-openssl=../openssl-1.1.0h --with-openssl-opt='-O3 -fPIC' --user=www --group=www
	make && make install
fi


#install redis


cd ~
redisPath=/webser/soft/redis
if [[ ! -d "$redisPath" ]];then
	mkdir -p $redisPath
fi
if [[ ! -f "${redisPath}/bin/redis-cli" ]];then
	if [[ ! -f "redis-4.0.11.tar.gz" ]];then
		wget http://download.redis.io/releases/redis-4.0.11.tar.gz
		if [[ ! -d "redis-4.0.11" ]];then
			tar xzf redis-4.0.11.tar.gz
		fi
	fi
	cd redis-4.0.11
	make clean
	make && make PREFIX=$redisPath install
	cp ./redis.conf ${redisPath}/redis.conf
fi

