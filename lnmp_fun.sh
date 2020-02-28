#!/usr/bin/env bash
# !/bin/bash

sourcePath="/usr/local/src"
processor=$(cat /proc/cpuinfo | grep processor | wc -l)

function init
{

	echo -e "LNMP安装脚本 \n"
	echo -e "输入要安装的软件：\n"
	echo -e " 1 安装Tengine \n 2 安装Mysql \n 3 安装PHP \n"

	
	read -t 30 -p "请输入号码:" num
	echo -e "\n";

	if [[ "$num" == "1" ]] ;then

		#初始化
		installNginx
		createNginxScript
	elif [[ "$num" == "2" ]];then
			
			installMysql
			createMysqlScripty
	elif [[ "$num" == "3" ]]; then
		installPhp
		createPhpScript
	else
		echo "输入错误"
	fi

}

function installNginx()
{
	
	systemdDir="/etc/systemd/system"
	if [ ! -d "$systemdDir" ]; then
　　		mkdir "$systemdDir"  
	fi

		#判断目录是否存在
	if [ ! -d "$sourcePath" ];then
		mkdir $sourcePath
	fi

	#判断是否安装了Git
	type git

	if [ $? != 0 ];then
		#安装git
	 	apt-get -y install git
 	fi

	#创建用户和组
	groupadd -f www
	useradd -g www www

	cd $sourcePath

	#安装nginx依赖
	apt-get install -y build-essential libpcre3-dev libssl-dev 

	nginxPath="$sourcePath/tengine"

	#如果nginx是没有下载则是下载Tengine
	if [ ! -f "$nginxPath" ];then
		#wget http://tengine.taobao.org/download/tengine-2.2.0.tar.gz
		#tar -zxvf tengine-2.2.0.tar.gz
		git clone https://gitee.com/mirrors/Tengine.git tengine 
	fi


	#缓存
	if [ ! -f "$sourcePath/ngx_cache_purge-2.3.tar.gz" ];then
		wget http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz
		tar -zxvf ngx_cache_purge-2.3.tar.gz
	fi


	#语法解析
	if [ ! -f "$sourcePath/pcre-8.34.tar.gz" ];then
		wget http://sourceforge.net/projects/pcre/files/pcre/8.34/pcre-8.34.tar.gz
		tar -zxvf pcre-8.34.tar.gz
	fi

	cd tengine

	./configure \
	--prefix=/usr/local/nginx \
	--sbin-path=/usr/local/nginx/sbin/nginx \
	--conf-path=/usr/local/nginx/conf/nginx.conf \
	--error-log-path=/usr/local/nginx/log/error.log \
	--http-log-path=/usr/local/nginx/log/access.log \
	--pid-path=/usr/local/nginx/run/nginx.pid \
	--user=www \
	--group=www \
	--with-http_ssl_module \
	--with-http_flv_module \
	--with-http_stub_status_module \
	--with-http_gzip_static_module \
	--http-client-body-temp-path=/usr/local/nginx/tmp/client \
	--http-proxy-temp-path=/usr/local/nginx/tmp/proxy/ \
	--http-fastcgi-temp-path=/usr/local/nginx/tmp/fcgi/ \
	--add-module=../ngx_cache_purge-2.3 \
	--with-pcre=../pcre-8.34 \
	--without-http_gzip_module

	if [ $? -gt "0" ];then
		echo "configure  nginx error"
		exit 1
	fi

	make && make install
	
	#创建执行目录
		#判断目录是否存在
	if [ ! -d "/usr/local/nginx/tmp/client" ];then
		mkdir -p /usr/local/nginx/tmp/client
	fi

	#启动nginx
	#/usr/local/nginx/sbin/nginx 

	if [ $? -eq "0" ];then
		echo "nginx install successd"
	else
		echo "nginx install feild"
	fi

	echo "[Unit] \n" 

	
	#createNginxScript

}


function createNginxScript()
{

	scriptFile="/etc/systemd/system/nginx.service"
	echo "[Unit]" > $scriptFile
	echo "Description=nginx - high performance web server" >> $scriptFile
	echo "After=network.target remote-fs.target nss-lookup.target" >> $scriptFile
	echo  -e "\n" >> $scriptFile

	echo "[Service]" >> $scriptFile
	echo "Type=forking" >> $scriptFile
	echo "ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf" >> $scriptFile
	echo "ExecReload=/usr/local/nginx/sbin/nginx -s reload" >> $scriptFile
	echo "ExecStop=/usr/local/nginx/sbin/nginx -s stop" >> $scriptFile

	echo  -e "\n" >> $scriptFile
	echo "[Install]" >> $scriptFile
	echo "WantedBy=multi-user.target" >> $scriptFile
	echo -e "\n" >> $scriptFile

	systemctl enable nginx.service

	#systemctl disable nginx.service

}


function installMysql
{

	cd $sourcePath
	
	mysqlVersion="mysql-8.0.19.tar.gz"

	#C++语法解析器
	if [ ! -d "$sourcePath/boost_1_70_0" ];then
		wget https://nchc.dl.sourceforge.net/project/boost/boost/1.70.0/boost_1_70_0.tar.gz
		tar -zxvf boost_1_70_0.tar.gz
	fi



	#下载Mysql源码
	if [ ! -f "$sourcePath/mysql-8.0.19.tar.gz" ];then
		wget https://cdn.mysql.com//Downloads/MySQL-8.0/mysql-8.0.19.tar.gz
		tar -zxvf mysql-8.0.19.tar.gz
	fi


	apt-get install -y build-essential libncurses5-dev cmake libboost-dev libaio1 libaio-dev

	cd mysql-8.0.19

	#安装前准备及目录设置
	groupadd mysql
	useradd -g mysql mysql
	mkdir /var/www
	mkdir -p /var/mysql/
	mkdir -p /var/mysql/data/
	mkdir -p /var/mysql/log/
	mkdir -p /var/mysql/share
	chmod -R 777 /var/mysql/data/


	#cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS:STRING=utf8,gbk -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 -DMYSQL_DATADIR=/var/mysql/data  -DSYSCONFDIR=/var/mysql -DDOWNLOAD_BOOST=0 -DWITH_BOOST=/usr/local/src/boost_1_59_0

	cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
	-DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
	-DEXTRA_CHARSETS=all \
	-DDEFAULT_CHARSET=utf8mb4 \
	-DDEFAULT_COLLATION=utf8mb4_general_ci \
	-DWITH_MYISAM_STORAGE_ENGINE=1 \
	-DWITH_INNOBASE_STORAGE_ENGINE=1 \
	-DWITH_READLINE=1 \
	-DENABLED_LOCAL_INFILE=1 \
	-DMYSQL_DATADIR=/var/mysql/data \
	-DSYSCONFDIR=/var/mysql \
	-DDOWNLOAD_BOOST=1 \
	-DWITH_BOOST=/usr/local/src/boost_1_70_0 \
	-DINSTALL_MYSQLSHAREDIR=/var/mysql/share \
	-DFORCE_INSOURCE_BUILD=1

	#编译安装
	make -j$processor && make install

	#设置配置文件
	chmod +w /usr/local/mysql
	chown -R mysql:mysql /usr/local/mysql
	chown -R mysql:mysql /var/mysql/
	#cp support-files/my-huge.cnf /var/mysql/my.cnf
	cd /usr/local/mysql
	mkdir mysql-files
	chown mysql:mysql mysql-files
	chmod 750 mysql-files

	# cp support-files/mysql.server /etc/init.d/mysqld
	cp sql/share/english/errmsg.sys /var/mysql/share/
	

	if [ -d "/var/mysql/data" ];then
			rm -fr /var/mysql/data
	fi


	#initialize-insecure 

	#初始化数据库
	/usr/local/mysql/bin/mysqld \
	--initialize \
	--user=mysql \
	--basedir=/var/mysql \
	--datadir=/var/mysql/data \
	--pid-file=/var/run/mysqld/mysqld.pid \
	--log-error=/var/log/mysqld.log

	cp support-files/mysql.server /etc/init.d/mysqld
	chmod a+x /etc/init.d/mysqld

	#初始化ssl
 	/usr/local/mysql/bin/mysql_ssl_rsa_setup
	#SET PASSWORD = PASSWORD('root') 
}



function createMysqlScripty
{

	scriptFile="/etc/systemd/system/mysqld.service"
	echo "[Unit]" > $scriptFile
	echo "Description=MySQL Server" >> $scriptFile
	echo "Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html" >> $scriptFile
	echo "After=network.target" >> $scriptFile
	echo "After=syslog.target" >> $scriptFile
	echo "" >> $scriptFile

	echo "[Install]" >> $scriptFile
	echo "WantedBy=multi-user.target" >> $scriptFile
	echo "" >> $scriptFile

	echo "[Service]" >> $scriptFile
	echo "Type=forking" >> $scriptFile
	echo "ExecStart=/etc/init.d/mysqld start" >> $scriptFile
	echo "EnvironmentFile=-/etc/sysconfig/mysql" >> $scriptFile
	echo "Restart=on-failure" >> $scriptFile
	echo "RestartPreventExitStatus=1" >> $scriptFile
	echo "" >> $scriptFile
	
	systemctl enable mysqld.service
}



function installPhp
{

	#安装依赖
	apt-get install -y libiconv-hook-dev libmcrypt-dev libxml2-dev libmysqlclient-dev libcurl4-openssl-dev libjpeg8-dev  libfreetype6-dev

	cd $sourcePath

    if [ ! -f "/usr/lib/libssl.so" ];then
        ln -s /usr/lib/x86_64-linux-gnu/libssl.so  /usr/lib 
    fi
    

	#zlib
	if [ ! -f "$sourcePath/libzip-1.2.0.tar.gz" ];then
		wget https://nih.at/libzip/libzip-1.2.0.tar.gz
		tar -zxvf libzip-1.2.0.tar.gz
		cd libzip-1.2.0
		./configure 
		make && make install
	fi
	
	#zlib
	if [ ! -f "$sourcePath/zlib-1.2.11.tar.gz" ];then
		 wget http://www.zlib.net/zlib-1.2.11.tar.gz
		tar -zxvf zlib-1.2.11.tar.gz
		cd zlib-1.2.11
		./configure 
		make && make install
		cp /usr/local/lib/libzip/include/zipconf.h /usr/local/include/zipconf.h
	fi

	#下载PHP
	if [ ! -d "$sourcePath/php-7.3.2" ];then
		wget http://cn2.php.net/distributions/php-7.3.2.tar.gz
		tar -zxvf php-7.3.2.tar.gz
	fi

	cd php-7.3.2

	./configure -prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr -enable-xml -disable-rpath -enable-bcmath -enable-shmop -enable-sysvsem -enable-inline-optimization --with-curl  -enable-mbregex -enable-fpm -enable-mbstring  -enable-ftp --with-gd  --with-openssl --with-mhash -enable-pcntl -enable-sockets --with-xmlrpc -enable-zip -enable-soap --without-pear --with-gettext  --enable-mysqlnd   --with-pdo-mysql --with-fpm-user=www --with-fpm-group=www --disable-fileinfo

	 #编译安装
	 make -j && make install 

	 #fpm配置
	 cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf

	 cp php.ini-production /usr/local/php/etc/php.ini

	 cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm

	 cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf

	 chmod +x /etc/init.d/php-fpm

}



function createPhpScript
{


	scriptFile="/etc/systemd/system/php-fpm.service"
	echo "[Unit]" > $scriptFile
	echo "Description=The PHP FastCGI Process Manager" >> $scriptFile
	echo "After=syslog.target network.target" >> $scriptFile
	echo -e "\n" >> $scriptFile
	echo "[Service]" >> $scriptFile
	echo "Type=simple" >> $scriptFile
	echo "PIDFile=/run/php-fpm.pid" >> $scriptFile
	echo "ExecStart=/usr/local/php/sbin/php-fpm --nodaemonize --fpm-config /usr/local/php/etc/php-fpm.conf" >> $scriptFile
	echo "ExecReload=/bin/kill -USR2 $MAINPID" >> $scriptFile
	echo "ExecStop=/bin/kill -SIGINT $MAINPID" >> $scriptFile
	echo -e "\n" >> $scriptFile

	echo "[Install]" >> $scriptFile
	echo "WantedBy=multi-user.target" >> $scriptFile

	systemctl enable php-fpm.service
}


init
