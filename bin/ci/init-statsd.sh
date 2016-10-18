#!/bin/bash

apt-get install -y nodejs
apt-get install -y git
git clone https://github.com/etsy/statsd.git
cd statsd
echo '{port: 8125, mgmt_port: 8126, backends: [\"./backends/console\"]}' > config.js
nodejs stats.js config.js