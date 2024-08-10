#!/bin/bash

# 依赖项
DEPENDENCIES=("curl" "jq" "openssl")

# 检查并安装依赖项
for dep in "${DEPENDENCIES[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        echo "$dep 未安装，正在安装..."
        sudo apt-get update
        sudo apt-get install -y "$dep"
    fi
done

# 读取配置文件
CONFIG_URL="https://example.com/config.json"
CONFIG_FILE="config.json"

curl -s "$CONFIG_URL" -o "$CONFIG_FILE"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件未找到，请检查配置文件路径或 URL。"
    exit 1
fi

# 提取电子邮件地址
EMAIL=$(jq -r '.email' "$CONFIG_FILE")

if [ -z "$EMAIL" ]; then
    echo "配置文件中未找到电子邮件地址，请检查配置文件。"
    exit 1
fi

# 检查 Certbot 是否安装
if ! command -v certbot &> /dev/null; then
    echo "Certbot 未安装，正在安装..."
    sudo apt-get update
    sudo apt-get install -y certbot python3-certbot-nginx
fi

# 检查 Nginx 是否安装
if ! command -v nginx &> /dev/null; then
    echo "Nginx 未安装，正在安装..."
    sudo apt-get update
    sudo apt-get install -y nginx
fi

# 读取配置文件并处理
echo "正在配置 Nginx 和 SSL..."

for domain in $(jq -c '.domains[]' "$CONFIG_FILE"); do
    domain_name=$(echo "$domain" | jq -r '.domain')
    ports=$(echo "$domain" | jq -r '.ports | to_entries[] | "\(.key):\(.value)"')

    echo "配置域名: $domain_name"

    # SSL 证书路径
    SSL_CERT_PATH="/etc/letsencrypt/live/$domain_name/fullchain.pem"
    SSL_KEY_PATH="/etc/letsencrypt/live/$domain_name/privkey.pem"

    # 配置 Nginx
    NGINX_CONF="/etc/nginx/sites-available/$domain_name.conf"
    
    echo "创建 Nginx 配置文件: $NGINX_CONF"

    echo "server {
    listen 80;
    server_name $domain_name;
    return 301 https://\$host\$request_uri;
}" > "$NGINX_CONF"

    for port in $ports; do
        external_port=$(echo "$port" | cut -d ':' -f 1)
        internal_port=$(echo "$port" | cut -d ':' -f 2)

        if [ "$internal_port" != "443" ]; then
            echo "    location /api_$external_port/ {
        proxy_pass http://localhost:$internal_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }" >> "$NGINX_CONF"
        fi
    done

    echo "server {
    listen 443 ssl;
    server_name $domain_name;

    ssl_certificate $SSL_CERT_PATH;
    ssl_certificate_key $SSL_KEY_PATH;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://localhost:7078;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}" >> "$NGINX_CONF"

    # 激活配置并重启 Nginx
    sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl restart nginx || {
        echo "Nginx 配置错误，请检查配置文件。"
        exit 1
    }
    
    # 检查 SSL 证书是否到期
    if [ ! -f "$SSL_CERT_PATH" ]; then
        echo "SSL 证书不存在，正在获取证书..."
        sudo certbot --nginx -d "$domain_name" --non-interactive --agree-tos --email "$EMAIL"
    else
        echo "检查 SSL 证书是否过期..."
        certbot renew --dry-run
    fi
done

echo "Nginx 和 Certbot 配置完成。"