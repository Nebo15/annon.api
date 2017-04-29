psql gateway -c "delete from apis"
psql gateway -c "delete from plugins"

set api_name 'Test endpoint'
set api_request  (
  jq --monochrome-output \
     --compact-output \
     --null-input \
     '{
       "methods": ["GET"],
       "scheme": "http",
       "host": "localhost",
       "port": 1234,
       "path": "/my_test_endpoint"
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
set plugin_id (psql gateway -A -q -t -c "insert into plugins (name, api_id, is_enabled, settings, inserted_at, updated_at) values ('$plugin_name', $api_id, true, '$plugin_settings', now(), now()) returning id")

set plugin_name 'acl'
set plugin_settings (
  jq --monochrome-output \
     --compact-output \
     --null-input \
     '{
       "rules": [
         {
           "methods": ["GET"],
           "path": "^.*",
           "scopes": ["some_api:read", "some_api:write"]
         }
       ]
     }'
)
set plugin_id (psql gateway -A -q -t -c "insert into plugins (name, api_id, is_enabled, settings, inserted_at, updated_at) values ('$plugin_name', $api_id, true, '$plugin_settings', now(), now()) returning id")

# rules: [%{}]

set plugin_name 'scopes'
set plugin_settings (
  jq --monochrome-output \
     --compact-output \
     --null-input \
     '{
       "strategy": "oauth2",
       "url_template": "http://localhost:4000/admin/tokens/{token}/verify",
     }'
)
set plugin_id (psql gateway -A -q -t -c "insert into plugins (name, api_id, is_enabled, settings, inserted_at, updated_at) values ('$plugin_name', $api_id, true, '$plugin_settings', now(), now()) returning id")

curl -H "Authorization: Bearer UzR4aUl1RURQUE80R3BEWGlYVzJtZz09" http://localhost:1234/my_test_endpoint
