# Dockerfile to build Openresety Installed Containers with WAF
FROM centos:7.6.1810
MAINTAINER evi0s <wc810267705@163.com>

# Install dependencies
RUN yum update -y && \
    yum install -y readline-devel pcre-devel openssl-devel perl make gcc gcc-c++ git wget

# Install Openssl
RUN cd /usr/local/src/ && \
    wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1c.tar.gz  && \
    tar zxvf openssl-1.1.1c.tar.gz && \
    cd openssl-1.1.1c && \
    ./config shared zlib --prefix=/usr/local/openssl --openssldir=/usr/local/openssl --libdir=lib shared -Wl,-R,'$(LIBRPATH)' -Wl,--enable-new-dtags enable-ec_nistp_64_gcc_128 enable-tls1_3 && \
    make && make install && \
    echo "/usr/local/openssl/lib" >> /etc/ld.so.conf

# Install Openresety
RUN cd /usr/local/src/ && \
    wget --no-check-certificate https://openresty.org/download/openresty-1.15.8.1.tar.gz && \
    tar zxvf openresty-1.15.8.1.tar.gz

RUN cd /usr/local/src/openresty-1.15.8.1 && \
    sed -i '39d' /usr/local/src/openresty-1.15.8.1/bundle/nginx-1.15.8/auto/lib/openssl/conf && \
    sed -i '39d' /usr/local/src/openresty-1.15.8.1/bundle/nginx-1.15.8/auto/lib/openssl/conf && \
    sed -i '39d' /usr/local/src/openresty-1.15.8.1/bundle/nginx-1.15.8/auto/lib/openssl/conf && \
    sed -i '39d' /usr/local/src/openresty-1.15.8.1/bundle/nginx-1.15.8/auto/lib/openssl/conf && \
    sed -i '39a\\t    CORE_INCS="$CORE_INCS $OPENSSL/include"' /usr/local/src/openresty-1.15.8.1/bundle/nginx-1.15.8/auto/lib/openssl/conf && \
    sed -i '40a\\t    CORE_DEPS="$CORE_DEPS $OPENSSL/include/openssl/ssl.h"' /usr/local/src/openresty-1.15.8.1/bundle/nginx-1.15.8/auto/lib/openssl/conf && \
    sed -i '41a\\t    CORE_LIBS="$CORE_LIBS $OPENSSL/lib/libssl.a"' /usr/local/src/openresty-1.15.8.1/bundle/nginx-1.15.8/auto/lib/openssl/conf && \
    sed -i '42a\\t    CORE_LIBS="$CORE_LIBS $OPENSSL/lib/libcrypto.a"' /usr/local/src/openresty-1.15.8.1/bundle/nginx-1.15.8/auto/lib/openssl/conf && \
    ./configure --prefix=/usr/local/openresty \
        --with-luajit --with-http_stub_status_module \
        --with-pcre --with-pcre-jit --with-openssl=/usr/local/openssl \
        --with-http_v2_module --with-http_ssl_module \
        --with-http_realip_module --with-http_gzip_static_module \
        --with-openssl-opt="enable-tls1_3 enable-ec_nistp_64_gcc_128" && \
    gmake && gmake install

# Install WAF
RUN git clone https://github.com/unixhot/waf.git

RUN cp -a ./waf/waf /usr/local/openresty/nginx/conf/ && \
    rm -rf /usr/local/openresty/nginx/conf/waf/config.lua && \
    mkdir /usr/local/openresty/nginx/ssl && \
    mkdir /usr/local/openresty/waf_logs

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

COPY config.lua /usr/local/openresty/nginx/conf/waf/config.lua

# Add user nginx
RUN useradd -s /sbin/nologin nginx

# Chown dir
RUN chown -R nginx.nginx /usr/local/openresty/

# Expose ports
EXPOSE 80

EXPOSE 443

# Start Openresty
CMD /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"
