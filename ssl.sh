#!/bin/bash

# Function to check installed dependencies
check_dependencies() {
    echo "Checking dependencies..."

    DEPENDENCIES=("nginx" "certbot")
    for dep in "${DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "$dep is not installed."
        else
            echo "$dep is installed."
        fi
    done
}

# Function to install Nginx and Certbot
install_nginx_certbot() {
    echo "Installing Nginx and Certbot..."
    sudo apt-get update
    sudo apt-get install -y nginx certbot python3-certbot-nginx
    echo "Nginx and Certbot installation completed."
}

# Function to remove Nginx and Certbot
remove_nginx_certbot() {
    echo "Removing Nginx and Certbot..."
    sudo systemctl stop nginx
    sudo apt-get --purge remove nginx-common -y
    sudo apt-get --purge remove nginx* -y
    sudo apt-get autoremove

    sudo apt-get remove --purge certbot python3-certbot-nginx -y
    sudo apt-get autoremove
    sudo rm -rf /etc/nginx /etc/letsencrypt
    sudo rm -rf /var/lib/letsencrypt
    sudo rm -rf /var/log/letsencrypt

    which certbot
    echo "Nginx and Certbot removal completed."
}

# Function to add a new reverse proxy configuration
add_reverse_proxy() {
    read -p "Enter container port: " container_port
    read -p "Enter domain name: " domain_name
    read -p "Enter email address: " EMAIL

    # SSL certificate path
    SSL_CERT_PATH="/etc/letsencrypt/live/$domain_name/fullchain.pem"
    SSL_KEY_PATH="/etc/letsencrypt/live/$domain_name/privkey.pem"

    # Check if the SSL certificate exists
    if [ ! -f "$SSL_CERT_PATH" ]; then
        echo "SSL certificate does not exist, obtaining certificate..."
        if sudo certbot --nginx -d "$domain_name" --non-interactive --agree-tos --email "$EMAIL"; then
            echo "SSL certificate successfully obtained."
        else
            echo "Failed to obtain SSL certificate, please check the error log."
            exit 1
        fi
    else
        echo "SSL certificate already exists."
    fi

    # Configure Nginx
    NGINX_CONF="/etc/nginx/conf.d/$domain_name-$container_port.conf"

    echo "Creating Nginx configuration file: $NGINX_CONF"

    # Create the configuration file
    echo "server {
    listen 80;
    server_name $domain_name;
    return 301 https://\$host\$request_uri;
    location / {
        proxy_pass http://localhost:$container_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}" | sudo tee "$NGINX_CONF" > /dev/null

    echo "server {
    listen 443 ssl;
    server_name $domain_name;

    ssl_certificate $SSL_CERT_PATH;
    ssl_certificate_key $SSL_KEY_PATH;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://localhost:$container_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}" | sudo tee -a "$NGINX_CONF" > /dev/null

    # Activate the configuration and reload Nginx
    sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
    if sudo nginx -t; then
        sudo systemctl reload nginx
        echo "Nginx configuration succeeded and has been reloaded."
    else
        echo "Nginx configuration error, please check the configuration file."
        exit 1
    fi
}

# Function to remove a reverse proxy configuration
remove_reverse_proxy() {
    read -p "Enter the container port to remove: " container_port

    # Find the corresponding configuration file
    CONFIG_FILE=$(grep -l "proxy_pass http://localhost:$container_port;" /etc/nginx/conf.d/*.conf)

    if [ -z "$CONFIG_FILE" ]; then
        echo "No configuration file found for the specified port."
        return
    fi

    # Remove the configuration file
    sudo rm -f "$CONFIG_FILE"

    # Remove the symbolic link to the configuration file
    sudo unlink /etc/nginx/sites-enabled/$(basename "$CONFIG_FILE")

    # Prompt to delete the certificate
    read -p "Do you want to delete the SSL certificate associated with this configuration? (y/n): " delete_cert
    if [ "$delete_cert" = "y" ]; then
        domain_name=$(grep -oP "(?<=server_name )\S+" "$CONFIG_FILE")
        if [ -n "$domain_name" ]; then
            echo "Deleting SSL certificate..."
            sudo rm -rf "/etc/letsencrypt/live/$domain_name"
            sudo rm -rf "/etc/letsencrypt/archive/$domain_name"
            sudo rm -rf "/etc/letsencrypt/renewal/$domain_name.conf"
            echo "SSL certificate deleted."
        else
            echo "Unable to determine which SSL certificate to delete."
        fi
    fi

    # Reload Nginx
    if sudo nginx -t; then
        sudo systemctl reload nginx
        echo "Nginx configuration has been reloaded."
    else
        echo "Nginx configuration error, please check the configuration file."
        exit 1
    fi
}

# Function to check SSL automatic renewal status
check_auto_renewal() {
    if sudo systemctl is-enabled certbot.timer &> /dev/null; then
        echo "Auto-renewal is enabled."
        AUTO_RENEW_OPTION="Disable Auto-renewal"
    else
        echo "Auto-renewal is disabled."
        AUTO_RENEW_OPTION="Enable Auto-renewal"
    fi
}

# Function to enable or disable SSL automatic renewal
manage_auto_renewal() {
    if [ "$AUTO_RENEW_OPTION" == "Disable Auto-renewal" ]; then
        echo "Disabling auto-renewal..."
        sudo systemctl stop certbot.timer
        sudo systemctl disable certbot.timer
        echo "Auto-renewal has been disabled."
    else
        echo "Enabling auto-renewal..."
        sudo systemctl enable certbot.timer
        sudo systemctl start certbot.timer
        echo "Auto-renewal has been enabled."
    fi
}

# Main menu
while true; do
    echo "Please choose an action:"

    check_dependencies

    check_auto_renewal

    if ! command -v nginx &> /dev/null || ! command -v certbot &> /dev/null; then
        echo "1) Install Nginx and Certbot"
    else
        echo "1) Add Reverse Proxy"
        echo "2) Remove Reverse Proxy"
        echo "3) Remove Certbot and Nginx"
    fi

    echo "8) $AUTO_RENEW_OPTION"
    echo "9) Exit"

    read -p "Enter your choice: " choice

    case $choice in
        1)
            if ! command -v nginx &> /dev/null || ! command -v certbot &> /dev/null; then
                install_nginx_certbot
            else
                add_reverse_proxy
            fi
            ;;
        2)
            remove_reverse_proxy
            ;;
        3)
            remove_nginx_certbot
            ;;
        8)
            manage_auto_renewal
            ;;
        9)
            echo "Exiting program."
            break
            ;;
        *)
            echo "Invalid choice, please try again."
            ;;
    esac
done
