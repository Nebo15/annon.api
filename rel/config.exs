use Mix.Releases.Config,
  default_release: :default,
  default_environment: :default

cookie = :sha256
|> :crypto.hash(System.get_env("ERLANG_COOKIE") || "secret_erlang_cookie")
|> Base.encode64

environment :default do
  set pre_start_hook: "bin/hooks/pre-start.sh"
  set dev_mode: false
  set include_erts: false
  set include_src: false
  set cookie: cookie
  set overlay_vars: [
    inet_dist_listen_min: 9000,
    inet_dist_listen_max: 9100
  ]
end

release :gateway do
  set version: current_version(:gateway)
  set applications: [
    gateway: :permanent
  ]
end
