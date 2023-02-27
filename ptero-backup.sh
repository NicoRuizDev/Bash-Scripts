#!/bin/bash

# Clear the console
clear

# Define color variables
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "\e[1m\e[38;5;220mWelcome to Ptero-Backup!\e[0m"
echo ""
echo -e "${YELLOW}Made with love by NicoRuizDev\nhttps://github.com/NicoRuizDev/PteroBackup-web${NC}\n"

# Set the welcome message
echo -e "\e[1m\e[38;5;220mWelcome to Ptero-Backup!\e[0m"

# Check if the user is root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}" 
   exit 1
fi

# Install required packages
echo -e "${GREEN}Installing required packages...${NC}"
apt-get update
apt-get install -y nginx git npm python3-certbot-nginx
npm install -g pm2


# Hardcode the repository URL and the folder to clone the repository into
repo_url="http://github.com/username/repo.git"
folder="/path/to/folder"


# Clone the repository into the specified folder
echo -e "\e[32mCloning repository...\e[0m"
git clone $repo_url $folder

# Install dependencies using npm
echo -e "\e[32mInstalling dependencies using npm...\e[0m"
cd $folder
npm install

# Set the values of the 'AppLink' and 'AppPort' environment variables
read -p "Enter the value for AppLink: " applink_value
read -p "Enter the value for AppPort: " appport_value

# Update the .env file with the environment variable values
echo "AppLink=$applink_value" >> $folder/.env
echo "AppPort=$appport_value" >> $folder/.env

# Install PM2 globally
echo -e "\e[32mInstalling PM2...\e[0m"
npm install -g pm2

# Start the application using PM2
echo -e "\e[32mStarting the application using PM2...\e[0m"
pm2 start $folder/index.js --name "my-app"

# Install Nginx
echo -e "\e[32mInstalling Nginx...\e[0m"
apt-get update
apt-get install -y nginx

# Install Certbot and the Certbot Nginx plugin
echo -e "\e[32mInstalling Certbot and the Certbot Nginx plugin...\e[0m"
apt-get install -y certbot python3-certbot-nginx

# Create an SSL certificate with Certbot
echo -e "\e[32mCreating an SSL certificate with Certbot...\e[0m"
certbot --nginx --agree-tos --email youremail@example.com -d $applink_value

# Configure Nginx to use the SSL certificate
echo -e "\e[32mConfiguring Nginx to use the SSL certificate...\e[0m"
echo "server {
    listen 80;
    server_name $applink_value;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    server_name $applink_value;
    ssl_certificate /etc/letsencrypt/live/$applink_value/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$applink_value/privkey.pem;
    location / {
        proxy_pass http://127.0.0.1:$appport_value;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}" > /etc/nginx/sites-available/$applink_value

# Enable the Nginx configuration and restart Nginx
ln -s /etc/nginx/sites-available/$applink_value /etc/nginx/sites-enabled/
systemctl restart nginx

# Print a success message
echo "The repository has been cloned to $folder and the '.env' file has been updated with the 'AppLink' environment variable set to '$applink_value' and the 'AppPort' environment variable set to '$appport_value'. Dependencies have been installed using npm. The application has been started using PM2. An SSL certificate has been created and Nginx has been configured to use it."

# Add author credit
echo "Made with love by NicoRuizDev https://github.com/NicoRuizDev/Ptero-Backup"

# Exit the script
exit 0