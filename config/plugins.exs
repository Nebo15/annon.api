use Mix.Config

enabled_plugins = %{
  jwt: Annon.Plugins.JWT,
  validator: Annon.Plugins.Validator,
  acl: Annon.Plugins.ACL,
  proxy: Annon.Plugins.Proxy,
  idempotency: Annon.Plugins.Idempotency,
  ip_restriction: Annon.Plugins.IPRestriction,
  ua_restriction: Annon.Plugins.UARestriction,
  scopes: Annon.Plugins.Scopes,
  cors: Annon.Plugins.CORS,
}

config :annon_api, :plugins, enabled_plugins
config :annon_api, :plugin_names, Enum.map(Map.keys(enabled_plugins), &to_string/1)
