#!/bin/bash
set -xe

# Create API
API_ID=$(uuidgen)
API=$(curl --silent --request PUT --header "Content-Type: application/json" http://localhost:4001/apis/${API_ID} -d '{"api": {"request":{"scheme":"http","port":4000,"path":"/world","methods":["GET","POST"],"host":"localhost"},"name":"Sanity check"}}')
API_NAME=$(echo ${API} | jq -r '.data.name')

if [ "${API_NAME}" != "Sanity check" ]; then
  echo "Unable to create API. Error response: ${API}"
  exit 1
fi

# Add proxy plugin
PROXY=$(curl --silent --request PUT --header "Content-Type: application/json" http://localhost:4001/apis/${API_ID}/plugins/proxy -d '{"plugin": {"name":"proxy","is_enabled":true,"settings":{"scheme":"http","port":80,"path":"/","host":"httpbin.org","strip_api_path":true}}}')
PROXY_HOST=$(echo ${PROXY} | jq -r '.data.settings.host')

if [ "${PROXY_HOST}" != "httpbin.org" ]; then
  echo "Unable to create proxy plugin. Error response: ${PROXY}"
  exit 1
fi

sleep 1

# Issue a real request to proxy
REQUEST=$(curl --silent --request GET http://localhost:4000/world/get?my_param=my_value)
REQUEST_VALUE=$(echo ${REQUEST} | jq -r '.args.my_param')

if [ "${REQUEST_VALUE}" != "my_value" ]; then
  echo "Unexpected responce from test upstream: ${REQUEST}"
  exit 1
else
  echo "Sanity check was successfull. All good!"
  exit 0
fi
