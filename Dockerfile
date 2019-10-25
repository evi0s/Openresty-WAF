# Dockerfile to build Openresety Installed Containers with WAF (alpine)
FROM alpine:3.10.3
MAINTAINER evi0s

RUN echo "====> Install dependencies" && \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' \
        /etc/apk/repositories && \
    apk update && \
    apk add --no-cache readline-dev pcre-dev \
        perl make gcc g++ git zlib-dev libc-dev linux-headers && \
    echo "====> Install Openssl" && \
    cd /tmp && \
    wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1c.tar.gz && \
    tar zxf openssl-1.1.1c.tar.gz && \
    cd openssl-1.1.1c && \
    ./config shared zlib --prefix=/usr/local/openssl \
        --openssldir=/usr/local/openssl \
        --libdir=lib shared -Wl,-R,'$(LIBRPATH)' \
        -Wl,--enable-new-dtags enable-ec_nistp_64_gcc_128 enable-tls1_3 && \
    make -j$(($(grep processor /proc/cpuinfo | wc -l) * 2)) && \
    make install && rm -rf /usr/local/openssl/share/* && \
    echo "/usr/local/openssl/lib" >> /etc/ld.so.conf && \
    export PATH=$PATH:/usr/local/openssl/bin && \
    echo "===> Install Openresty" && \
    cd /tmp && \
    wget --no-check-certificate https://openresty.org/download/openresty-1.15.8.1.tar.gz && \
    tar zxf openresty-1.15.8.1.tar.gz && \
    cd openresty-1.15.8.1 && \
    sed -i 's/\/\.openssl//g' bundle/nginx-1.15.8/auto/lib/openssl/conf && \
    ./configure --prefix=/usr/local/openresty \
        --with-luajit --with-http_stub_status_module \
        --with-pcre --with-pcre-jit --with-openssl=/usr/local/openssl \
        --with-http_v2_module --with-http_ssl_module \
        --with-http_realip_module --with-http_gzip_static_module \
        --with-openssl-opt="enable-tls1_3 enable-ec_nistp_64_gcc_128" && \
    make -j$(($(grep processor /proc/cpuinfo | wc -l) * 2)) && \
    make install && \
    echo "===> Gen Certs" && \
    mkdir /usr/local/openresty/nginx/ssl && \
    cd /usr/local/openresty/nginx/ssl/ && \
    openssl genrsa -des3 -passout pass:Pa5sK3y -out ca.key 2048 && \
    openssl req -passin pass:Pa5sK3y -new -subj "/C=CN/ST=Beijing/L=LocalDomain/O=LocalDomain/OU=LocalDomain/CN=localhost" \
        -key ca.key -out ca.csr && \
    mv ca.key ca.origin.key && \
    openssl rsa -passin pass:Pa5sK3y -in ca.origin.key -out privkey.pem && \
    openssl x509 -req -days 3650 -in ca.csr -signkey privkey.pem -out fullchain.pem && \
    openssl dhparam -out dhparam.pem 2048 && \
    echo "===> Install WAF" && \
    cd /tmp && \
    git clone https://github.com/unixhot/waf.git && \
    cp -a ./waf/waf /usr/local/openresty/nginx/conf/ && \
    rm -rf /usr/local/openresty/nginx/conf/waf/config.lua && \
    mkdir /usr/local/openresty/waf_logs && \
    apk del gcc g++ make git perl linux-headers --purge && \
    rm -rf /tmp/* && rm -rf /var/cache/apk/*

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

COPY config.lua /usr/local/openresty/nginx/conf/waf/config.lua

# Add user nginx & chown dir
RUN adduser -s /sbin/nologin -D nginx && \
    chown -R nginx:nginx /usr/local/openresty/

# Expose ports
EXPOSE 80 443

# Start Openresty
CMD /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"

