#!/usr/bin/env python

import os


def generate_nginx_config(hostnames: str = None):
    """
    Generate an Nginx configuration for a load balancing
    """

    hosts = hostnames.split(",")

    config = "upstream backend {\n"
    config += "    zone backend 64k;\n"  # Define a shared memory zone
    config += "    least_conn;\n"  # Use the least number of connections

    for host in hosts:
        config += f"    server {host.strip()};\n"

    config += "}\n\n"
    config += "server {\n"
    config += "    listen $SERVER_PORT;\n"
    config += "    server_name $SERVER_NAME;\n"
    config += "\n"
    config += "    location / {\n"
    config += "        proxy_pass http://backend;\n"
    config += "        proxy_set_header  Host $host;\n"
    config += "        proxy_set_header X-Real-IP $remote_addr;\n"
    config += "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n"
    config += "        proxy_set_header X-Forwarded-Proto $scheme;\n"
    config += "    }\n"
    config += "    location /status {\n"
    config += "       access_log off;\n"
    config += "       default_type text/plain;\n"
    config += "       expires -1;\n"
    config += "       return 200 'Server address: $server_addr:$server_port\\nServer name: $server_name\\nDate: $time_local\\nURI: $request_uri\\nRequest ID: $request_id\\n';\n"
    config += "    }\n"
    config += "    location /health {\n"
    config += "         access_log off;\n"
    config += "         default_type application/json;\n"
    config += '         return 200 \'{"status":"$status","version":"$APP_VERSION"}\';\n'
    config += "     }\n"
    config += "    add_header X-LB-Version ${APP_VERSION};\n"
    config += "}\n"

    return config


if __name__ == "__main__":
    hostnames = os.environ.get("HOSTNAMES")
    if not hostnames:
        raise ValueError("The environment variable HOSTNAMES must be set")

    nginx_config = generate_nginx_config(hostnames)

    # Write the generated config to a file, see: 20-envsubst-on-templates.sh
    with open("nginx.conf.template", "w") as file:
        file.write(nginx_config)
