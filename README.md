# Openresty WAF

Openresty with WAF installed

Force HTTPS & HTTP2

SSL Cert & PrivKey required

## Components

* **Openresty**
  
  version 1.15.8.1

* **Nginx**
  
  version 1.15.8

* **Openssl**

  version 1.1.1c
  
* **WAF**

  [unixhot/waf](https://github.com/unixhot/waf)

## Build

```bash
git clone https://github.com/evi0s/Openresty-WAF.git
cd Openresty-WAF
docker build -t user/name .
```

## Deploy

Copy SSL Cert & Privkey to a path

```bash
mkdir /home/user/openresty-waf
cd /home/user/openresty-waf
mkdir ssl && mkdir html
cp /path/to/your/fullchain ./ssl/fullchain.pem # Fullchain name unmodifiable
cp /path/to/your/privkey ./ssl/privkey.pem # Private key name unmodifiable
openssl dhparam -out ./ssl/dhparam.pem 2048
```

Deploy

```bash
docker run -it -d \
           -p 80:80 \
           -p 443:443 \
           -v /home/user/openresty-waf/ssl/:/usr/local/openresty/nginx/ssl/:ro \
           -v /home/user/openresty-waf/html/:/usr/local/openresty/nginx/html/ \
           --name=nginx-waf \
           user/name
```

## Deploy without build

```bash
docker run -it -d \
           -p 80:80 \
           -p 443:443 \
           -v /home/user/openresty-waf/ssl/:/usr/local/openresty/nginx/ssl/:ro \
           -v /home/user/openresty-waf/html/:/usr/local/openresty/nginx/html/ \
           --name=nginx-waf \
           evi0s/openresty-waf
```

## Configs

* WAF logs

  ```
  /usr/local/openresty/waf_logs/
  ```

  Can be modified in config.lua
  
* Nginx access log

  ```
  /usr/local/openresty/nginx/access.log
  ```
  
  Can be modified in nginx.conf
  
* WAF warning html

  Can be modified in config.lua
  
* WAF CC Blocking

  Default: **10** Requests Max within **60** seconds
  
  Can be modified in config.lua
  
## Links

* [Openresty](http://openresty.org/cn/)
* [unixhot/waf](https://github.com/unixhot/waf)

