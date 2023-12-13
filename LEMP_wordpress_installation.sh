#!/bin/bash

# Function to read user input with a prompt
read_input() {
    read -p "$1: " input
    echo "$input"
}

# Get server name, root directory, WordPress location, database username, database name, and password from the user
server_conf_name=$(read_input "Enter the Configuration name (e.g., site1.conf)")
server_name=$(read_input "Enter server name (e.g., site1.techopswizards.in)")
root_directory_for_wordpress=$(read_input "Enter root directory (e.g., /var/www/site1.techopswizards.in)")
db_username=$(read_input "Enter MySQL database username")
db_name=$(read_input "Enter MySQL database name")
db_password=$(read_input "Enter MySQL database password")

# Check if the root directory already exists
if [ -d "$root_directory_for_wordpress" ]; then
    echo "Error: Root directory '$root_directory_for_wordpress' already exists. Exiting."
    exit 1
fi

# Download and extract WordPress into /tmp
wordpress_url="https://wordpress.org/latest.tar.gz"
temp_dir="/tmp/wordpress_tmp"
mkdir -p "$temp_dir"
wget -O "$temp_dir/wordpress.tar.gz" "$wordpress_url"

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to download WordPress. Please check your internet connection."
    exit 1
fi

# Extract WordPress
tar -xzf "$temp_dir/wordpress.tar.gz" -C "$temp_dir"

# Move WordPress files to the root directory
sudo mv "$temp_dir/wordpress" "$root_directory_for_wordpress"

# Check if the move operation was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to move WordPress files to '$root_directory_for_wordpress'."
    exit 1
fi

# Set proper permissions for www-data
sudo chown -R www-data:www-data "$root_directory_for_wordpress"
sudo chmod -R 755 "$root_directory_for_wordpress"

# Clean up temporary directory
rm -r "$temp_dir"

# Nginx configuration
nginx_config="server {
    listen 80;
    server_name $server_name www.$server_name;

    root $root_directory_for_wordpress;
    index index.php index.html index.htm;

    access_log /var/log/nginx/$server_name-access.log;
    error_log /var/log/nginx/$server_name-error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}"

# Create Nginx configuration file
echo "$nginx_config" | sudo tee "/etc/nginx/sites-available/$server_conf_name"

# Check if the symbolic link already exists
if [ -e "/etc/nginx/sites-enabled/$server_conf_name" ]; then
    echo "Warning: Symbolic link '/etc/nginx/sites-enabled/$server_conf_name' already exists. Skipping link creation."
else
    # Create symbolic link to enable the site
    sudo ln -s "/etc/nginx/sites-available/$server_conf_name" "/etc/nginx/sites-enabled/"
fi

# Reload Nginx to apply changes if the service is active
if sudo systemctl is-active --quiet nginx; then
    sudo systemctl reload nginx
else
    echo "Warning: nginx.service is not active, cannot reload."
fi

# Check if the database already exists
if sudo mysql -e "use $db_name" 2>/dev/null; then
    echo "Error: MySQL database '$db_name' already exists. Please choose a different database name."
    exit 1
else
    # Create MySQL database and user for WordPress
    sudo mysql -e "CREATE DATABASE $db_name;"
    sudo mysql -e "CREATE USER '$db_username'@'localhost' IDENTIFIED BY '$db_password';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_username'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
fi

# Display completion message
echo "WordPress installed successfully at $root_directory_for_wordpress"
echo "MySQL database '$db_name' and user '$db_username' created with the provided password"
