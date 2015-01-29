# Redis
if [ -x /usr/local/bin/redis-server -a "`/usr/local/bin/redis-server -v | cut -d ' ' -f3`" = "v=2.8.7" ]; then
  echo "Redis already installed with the expected version."
else
  mkdir -p ~/tmp
  cd ~/tmp
  curl -O http://download.redis.io/releases/redis-2.8.7.tar.gz
  echo "3fc0bcdf6aef491ca2f08e62e4de7bc2  redis-2.8.7.tar.gz" | md5sum -c
  echo "2c484699628f02c1e1a0637f2b62ca8a206a8771e2c9b3821a34800b5893b90890048363b4a9b1202283dee46e087a0e5e7acc0d46801b844b5217f3ca65b3d9  redis-2.8.7.tar.gz" | sha512sum -c
  tar xvfz redis-2.8.7.tar.gz
  cd redis-2.8.7
  cd deps; make hiredis lua jemalloc linenoise
  cd ..
  make && make install
  mkdir -p /var/lib/redis
  chown -R redis:redis /var/lib/redis
  mkdir -p /var/log/redis
  touch /var/log/redis/redis-server.log
  chown -R redis:redis /var/log/redis
fi
