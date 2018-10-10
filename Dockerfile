# Dockerfile to build Openresety Installed Containers with WAF
FROM centos:7.5.1804
MAINTAINER evi0s <wc810267705@163.com>

# Install dependencies
RUN yum update -y && \
    yum install -y readline-devel pcre-devel openssl-devel perl make gcc gcc-c++ git wget

# Install Openssl

RUN cd /usr/local/src/ && \
    wget --no-check-certificate https://www.openssl.org/source/openssl-1.0.2j.tar.gz && \
    tar zxvf openssl-1.0.2j.tar.gz && \
    cd openssl-1.0.2j && ./config shared zlib && \
    make && make install && \
    ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl && \
    ln -s /usr/local/ssl/include/openssl /usr/include/openssl && \
    echo "/usr/local/ssl/lib" >> /etc/ld.so.conf

# Install Openresety
ADD https://openresty.org/download/openresty-1.13.6.2.tar.gz /usr/local/src

RUN cd /usr/local/src/ && \
    tar zxvf openresty-1.13.6.2.tar.gz

RUN cd /usr/local/src/openresty-1.13.6.2 && \
    sed -i '39d' /usr/local/src/openresty-1.13.6.2/bundle/nginx-1.13.6/auto/lib/openssl/conf && \
    sed -i '39d' /usr/local/src/openresty-1.13.6.2/bundle/nginx-1.13.6/auto/lib/openssl/conf && \
    sed -i '39d' /usr/local/src/openresty-1.13.6.2/bundle/nginx-1.13.6/auto/lib/openssl/conf && \
    sed -i '39d' /usr/local/src/openresty-1.13.6.2/bundle/nginx-1.13.6/auto/lib/openssl/conf && \
    sed -i '39a\\t    CORE_INCS="$CORE_INCS $OPENSSL/include"' /usr/local/src/openresty-1.13.6.2/bundle/nginx-1.13.6/auto/lib/openssl/conf && \
    sed -i '40a\\t    CORE_DEPS="$CORE_DEPS $OPENSSL/include/openssl/ssl.h"' /usr/local/src/openresty-1.13.6.2/bundle/nginx-1.13.6/auto/lib/openssl/conf && \
    sed -i '41a\\t    CORE_LIBS="$CORE_LIBS $OPENSSL/lib/libssl.a"' /usr/local/src/openresty-1.13.6.2/bundle/nginx-1.13.6/auto/lib/openssl/conf && \
    sed -i '42a\\t    CORE_LIBS="$CORE_LIBS $OPENSSL/lib/libcrypto.a"' /usr/local/src/openresty-1.13.6.2/bundle/nginx-1.13.6/auto/lib/openssl/conf && \
    ./configure --prefix=/usr/local/openresty-1.13.6.2 \
    --with-luajit --with-http_stub_status_module \
    --with-pcre --with-pcre-jit --with-openssl=/usr/local/ssl \
    --with-http_v2_module --with-http_ssl_module \
    --with-http_realip_module --with-http_gzip_static_module && \
    gmake && gmake install

RUN ln -s /usr/local/openresty-1.13.6.2 /usr/local/openresty

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
