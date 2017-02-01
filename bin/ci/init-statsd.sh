#!/bin/bash
DD_API_KEY=14fff8b0c473a7e27bb5833c72f29b2f bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/dd-agent/master/packaging/datadog-agent/source/install_agent.sh)"
sudo sh -c "echo 'listen_port: 17123' > /etc/dd-agent/datadog.conf"
sudo sh -c "echo 'use_dogstatsd: yes' > /etc/dd-agent/datadog.conf"
sudo sh -c "echo 'dogstatsd_port: 8125' > /etc/dd-agent/datadog.conf"

cat /etc/dd-agent/datadog.conf

sudo /etc/init.d/datadog-agent start
exit 1
