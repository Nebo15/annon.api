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
       "path": "/yo"
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

curl http://localhost:1234/yo

# 1.3 Add acl rule to API endpoint
# acl_params = %{
#   name: "acl",
#   is_enabled: true,
#   settings: %{
#     rules: [%{methods: ["POST"], path: "^.*", scopes: ["originator_loans:upload"]}]
#   }
# }
# HTTPoison.post("http://os-dev-gateway.nebo15.com:8080/apis/#{api_id}/plugins", Poison.encode!(acl_params), [{"Content-Type", "application/json"}])
#        |> IO.inspect
#
# # 1.4 Add scopes plugin to API endpoint
# scopes_params = %{
#   name: "scopes",
#   is_enabled: true,
#   settings: %{
#     strategy: "pcm",
#     url_template: "http://ec2-52-58-60-8.eu-central-1.compute.amazonaws.com:8081/0/api.svc/party/{party_id}/scopes"
#   }
# }
# HTTPoison.post("http://os-dev-gateway.nebo15.com:8080/apis/#{api_id}/plugins", Poison.encode!(scopes_params), [{"Content-Type", "application/json"}])
