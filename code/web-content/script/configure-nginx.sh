
api_endpoint=xxxxxxxxxx

cat <<EOF > /etc/nginx/sites-enabled/default
server {
    listen 81;
	
	# Load configuration files for the default server block.
	include /etc/nginx/default.d/*.conf;
    include /etc/nginx/mime.types;

	location /api {
        proxy_set_header Host \$proxy_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-User \$remote_user;

		proxy_set_header Authorization \$http_authorization;
		proxy_pass_header Authorization;

        proxy_pass https://$api_endpoint.execute-api.eu-west-1.amazonaws.com/api;               
        proxy_ssl_server_name on;
        proxy_ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        proxy_buffering off;

        resolver 8.8.8.8;
	}

    location / {
        root /mnt/c/MyCodeArea/content/dcv-web-portal/code/web-content/dist;
        index index.html;
        try_files index.html /index.html \$uri \$uri/;
    }
	location ~* \.(js|css)$ { 
        # Enable serving js and css files
        # Additional headers if needed
        root /mnt/c/MyCodeArea/content/dcv-web-portal/code/web-content/dist;
        index index.html;
	}	
}
EOF
service nginx restart
service nginx status
more /etc/nginx/sites-enabled/default

