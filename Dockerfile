# Dockerfile to build Openresety Installed Containers with WAF
FROM centos:7.6.1810
MAINTAINER evi0s

# Install dependencies
RUN yum update -y && \
    yum install -y readline-devel pcre-devel \
        openssl-devel perl make gcc gcc-c++ git wget

# Install Openssl
RUN cd /usr/local/src/ && \
    wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1c.tar.gz && \
    tar zxf openssl-1.1.1c.tar.gz && \
    cd openssl-1.1.1c && \
    ./config shared zlib --prefix=/usr/local/openssl --openssldir=/usr/local/openssl \
        --libdir=lib shared -Wl,-R,'$(LIBRPATH)' \
        -Wl,--enable-new-dtags enable-ec_nistp_64_gcc_128 enable-tls1_3 && \
    make -j$(($(grep processor /proc/cpuinfo | wc -l) * 2)) && \
    make install && rm -rf /usr/local/openssl/share/* && \
    echo "/usr/local/openssl/lib" >> /etc/ld.so.conf && \
    rm -rf /usr/local/src/*

# Install Openresety
RUN cd /usr/local/src/ && \
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
    make install && rm -rf /usr/local/src/*

# Gen certs for testing
RUN export PATH=$PATH:/usr/local/openssl/bin && \
    mkdir /usr/local/openresty/nginx/ssl && \
    cd /usr/local/openresty/nginx/ssl/ && \
    openssl genrsa -des3 -passout pass:Pa5sK3y -out ca.key 2048 && \
    openssl req -passin pass:Pa5sK3y -new \
        -subj "/C=CN/ST=Beijing/L=LocalDomain/O=LocalDomain/OU=LocalDomain/CN=localhost" \
        -key ca.key -out ca.csr && \
    mv ca.key ca.origin.key && \
    openssl rsa -passin pass:Pa5sK3y -in ca.origin.key -out privkey.pem && \
    openssl x509 -req -days 3650 -in ca.csr -signkey privkey.pem -out fullchain.pem && \
    openssl dhparam -out dhparam.pem 2048

# Install WAF
RUN git clone https://github.com/unixhot/waf.git && \
    cp -a ./waf/waf /usr/local/openresty/nginx/conf/ && \
    rm -rf /usr/local/openresty/nginx/conf/waf/config.lua && \
    mkdir /usr/local/openresty/waf_logs

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

COPY config.lua /usr/local/openresty/nginx/conf/waf/config.lua

# Add user nginx & chown dir
RUN useradd -s /sbin/nologin nginx && \
    chown -R nginx.nginx /usr/local/openresty/

# Expose ports
EXPOSE 80 443

# Start Openresty
CMD /usr/local/openresty/nginx/sbin/nginx -g "daemon off;"

