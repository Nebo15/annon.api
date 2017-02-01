#!/bin/bash
DD_API_KEY=14fff8b0c473a7e27bb5833c72f29b2f bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/dd-agent/master/packaging/datadog-agent/source/install_agent.sh)"

cat /etc/dd-agent/datadog.conf

exit 1
