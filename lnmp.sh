#ubuntu 下编译安装LNMP
sourcePath="/usr/local/src"

apt-get update 
apt-get upgrade -y

#创建用户和组
groupadd -f www
useradd -g www www

#软件下载目录
cd /usr/local/src

#判断目录是否存在
if [ ! -d "$sourcePath" ];then
	mkdir $sourcePath
fi

#安装nginx依赖
apt-get install -y build-essential libpcre3-dev libssl-dev 


#安装git
 apt-get -y install git

#安装tengine
git clone git://github.com/alibaba/tengine.git
wget http://tengine.taobao.org/download/tengine-2.2.0.tar.gz
tar -zxvf tengine-2.2.0.tar.gz
if [ $? -gt "0" ];then
	echo "tengine download Failure"
	exit 1
fi
#nginx catch
wget http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz
if [ $? -gt "0" ];then
	echo "ngx_cache_purge download Failure"
	exit 1
fi

#语法解析
wget http://sourceforge.net/projects/pcre/files/pcre/8.34/pcre-8.34.tar.gz
if [ $? -gt "0" ];then
	echo "pcre-8.34 download Failure"
	exit 1
fi
#解压目录
tar -zxvf ngx_cache_purge-2.3.tar.gz
tar -zxvf pcre-8.34.tar.gz

#进入nginx
cd tengine-*

#配置tengine
./configure --prefix=/usr/local/nginx --sbin-path=/usr/local/nginx/sbin/nginx --conf-path=/usr/local/nginx/conf/nginx.conf --error-log-path=/usr/local/nginx/log/error.log --http-log-path=/usr/local/nginx/log/access.log --pid-path=/usr/local/nginx/run/nginx.pid --user=www --group=www --with-http_ssl_module --with-http_flv_module --with-http_stub_status_module --with-http_gzip_static_module --http-client-body-temp-path=/usr/local/nginx/tmp/client --http-proxy-temp-path=/usr/local/nginx/tmp/proxy/ --http-fastcgi-temp-path=/usr/local/nginx/tmp/fcgi/ --add-module=../ngx_cache_purge-2.3 --with-pcre=../pcre-8.34
if [ $? -gt "0" ];then
	echo "configure  nginx error"
	exit 1
fi
#编译安装
make && make install

#创建执行目录
mkdir -p /usr/local/nginx/tmp/client

#启动nginx
/usr/local/nginx/sbin/nginx 



#安装mysql
cd /usr/local/src

#下载boost
#wget https://sourceforge.net/projects/boost/files/boost/1.62.0/boost_1_62_0.tar.gz
wget https://nchc.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz
if [ $? -gt "0" ];then
	echo "boost_1_62_0.tar.gz  download Failure"
	exit 1
fi
#解压
tar -zxvf boost_1_59_0.tar.gz

#cd boost_

#下载mysql
#wget http://dev.mysql.com/get/Downloads/MySQL-5.5/mysql-5.5.30.tar.gz
#wget https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-boost-5.7.19.tar.gz
#wget http://101.110.118.69/dev.mysql.com/get/Downloads/MySQL-5.7/mysql-boost-5.7.16.tar.gz
#wget https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-5.7.19.tar.gz
if [ $? -gt "0" ];then
	echo "mysql-boost-5.7.16.tar.gz  download Failure"
	exit 1
fi


#安装mysql依赖
apt-get install -y build-essential libncurses5-dev cmake libboost-dev

#解压
tar -zxvf mysql-*

cd mysql-*

#安装前准备及目录设置
groupadd mysql
useradd -g mysql mysql
mkdir /var/www
mkdir -p /var/mysql/
mkdir -p /var/mysql/data/
mkdir -p /var/mysql/log/
mkdir -p /var/mysql/share
chmod -R 777 /var/mysql/data/

#配置
#cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS:STRING=utf8,gbk -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 -DMYSQL_DATADIR=/var/mysql/data  -DSYSCONFDIR=/var/mysql -DDOWNLOAD_BOOST=0 -DWITH_BOOST=/usr/local/src/boost_1_59_0
cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DMYSQL_DATADIR=/var/mysql/data \
-DSYSCONFDIR=/var/mysql \
-DDOWNLOAD_BOOST=0 \
-DWITH_BOOST=/usr/local/src/boost_1_59_0


#编译安装
make && make install

#设置配置文件
chmod +w /usr/local/mysql
chown -R mysql:mysql /usr/local/mysql
chown -R mysql:mysql /var/mysql/
#ln -s /usr/local/mysql/lib/libmysqlclient.so.18
#ln -s /usr/local/mysql/lib/libmysqlclient.so.18 /usr/lib/libmysqlclient.so.18
#cp support-files/my-medium.cnf /var/mysql/my.conf
#cp support-files/my-huge.cnf /var/mysql/my.cnf
cp support-files/mysql.server /etc/init.d/mysqld
cp sql/share/english/errmsg.sys /var/mysql/share/
chmod a+x /etc/init.d/mysqld


#MySQL初始化安装
#/usr/local/mysql/scripts/mysql_install_db --defaults-file=/var/mysql/my.cnf --basedir=/usr/local/mysql --datadir=/var/mysql/data --user=mysql 
/usr/local/mysql/bin/mysqld --initialize --user=mysql --basedir=/var/mysql --datadir=/var/mysql/data --pid-file=/var/run/mysqld/mysqld.pid --log-error=/var/log/mysqld.log --defaults-file=/var/mysql/my.cnf 

#bo9Jejf26F%p
#/usr/local/mysql/scripts/mysql_install_db  --basedir=/usr/local/mysql --datadir=/var/mysql/data --user=mysql --pid-file=/var/run/mysqld/mysqld.pid --log-error=/var/log/mysqld.log --basedir=/usr/local/mysql --defaults-file=/var/mysql/my.cnf

if [ $? -gt "0" ];then
	echo "mysql_install_db  init Failure"
	exit 1
fi

#./mysql_install_db --user=mysql --datadir=/var/lib/mysql --socket=/var/lib/mysql/mysql.sock --pid-file=/var/run/mysqld/mysqld.pid --log-error=/var/log/mysqld.log --basedir=/usr/local/mysql

#开机启动
update-rc.d -f mysqld defaults

#备份系统的mysql
cp -fr /etc/mysql /var/backups/mysql.bak

#删除/ect/mysql 的配置，否则不能启动
rm -fr /ect/mysql/*


#启动mysql服务
/ect/init.d/mysqld start

#设置root初始密码
#mysqladmin -u root password "moneygomyhome.db"



#安装PHP
cd /usr/local/src
#安装依赖
apt-get install -y libiconv-hook-dev libmcrypt-dev libxml2-dev libmysqlclient-dev libcurl4-openssl-dev libjpeg8-dev libpng12-dev libfreetype6-dev

ln -s /usr/lib/x86_64-linux-gnu/libssl.so  /usr/lib

#下载PHP
#wget http://cn2.php.net/distributions/php-5.6.20.tar.gz
#wget http://cn2.php.net/distributions/php-7.0.7.tar.gz
wget http://cn2.php.net/distributions/php-7.1.0.tar.gz

if [ $? -gt "0" ];then
	echo "php-7.1.0.tar.gz  download Failure"
	exit 1
fi

#解压
tar -zxvf php-7.1.0.tar.gz

cd php-*

#配置
./configure -prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr -enable-xml -disable-rpath -enable-bcmath -enable-shmop -enable-sysvsem -enable-inline-optimization --with-curl  -enable-mbregex -enable-fpm -enable-mbstring --with-mcrypt -enable-ftp --with-gd -enable-gd-native-ttf --with-openssl --with-mhash -enable-pcntl -enable-sockets --with-xmlrpc -enable-zip -enable-soap --without-pear --with-gettext --with-mysqli=mysqlnd --with-mysql=mysqlnd --with-pdo-mysql --with-fpm-user=www --with-fpm-group=www

 #编译安装
 make && make install 

 #fpm配置
 cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf

 cp php.ini-production /usr/local/php/etc/php.ini

 cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm

 cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf

 chmod +x /etc/init.d/php-fpm
 
 #启动PHP-FPM
 /etc/init.d/php-fpm restart

 update-rc.c -f php-fpm defaults

 exit 0

 #libevent memcached需要
 wget https://github.com/libevent/libevent/releases/download/release-2.0.22-stable/libevent-2.0.22-stable.tar.gz
 tar -zxvf libevent-2.0.22-stable.tar.gz
 cd libevent-2.0.22-stable
 ./configure
 make && make install 

 #安装memcached 
 wget http://memcached.org/files/memcached-1.4.31.tar.gz
 tar -zxvf memcached-1.4.31.tar.gz
 cd memcached-1.4.31
 ./configure --prefix=/usr/local/memcached --with-libevent=/usr/local/libevent/ 
 make && make install

 #安装memcache扩展
 wget http://pecl.php.net/get/memcache-3.0.4.tgz
 tar -zxvf memcache-3.0.4.tgz 
  cd memcache-3.0.4/
  phpize 
  ./configure --with-php-config=/usr/local/php/bin/php-config
  make && make install


















