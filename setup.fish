psql gateway -c "delete from apis"

set api_name 'Test endpoint'
set api_request  (
  jq --monochrome-output \
     --compact-output \
     --null-input \
     '{
       "name": "Test endpoint",
       "request": {
          "methods": ["GET"],
          "scheme": "http",
          "host": "localhost",
          "port": 1234,
          "path": "/get"
        }
     }'
)
set api_id (psql gateway -A -q -t -c "insert into apis (name, request, inserted_at, updated_at) values ('$api_name', '$api_request', now(), now()) returning id")

set plugin_name 'proxy'
set plugin_settings (
  jq --monochrome-output \
     --compact-output \
     --null-input \
     '{
       "scheme": "http",
       "host": "httpbin.org",
       "port": 80,
       "path": "/get",
       "strip_api_path": true
     }'
)
set plugin_id (psql gateway -A -q -t -c "insert into plugins (name, is_enabled, settings, inserted_at, updated_at) values ('$plugin_name', true, '$plugin_settings', now(), now()) returning id")

curl http://localhost:1234/get
