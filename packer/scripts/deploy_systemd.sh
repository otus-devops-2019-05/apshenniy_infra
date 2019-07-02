#!/bin/bash

cat > /etc/systemd/system/puma.service <<EOF
[Unit]
Description=puma
After=network.target
[Service]
User=apshenniy
Group=apshenniy
Type=simple
WorkingDirectory=/home/apshenniy/reddit
ExecStart=/usr/local/bin/puma
TimeoutSec=300
[Install]
WantedBy=multi-user.target
