use Mix.Releases.Config,
  default_release: :default,
  default_environment: :default

# TODO: Set from ENV vars in start-time via vm.args
cookie = :sha256
|> :crypto.hash(System.get_env("ERLANG_COOKIE") || "secret_erlang_cookie")
|> Base.encode64

environment :default do
  set pre_start_hook: "bin/hooks/pre-start.sh"
  set dev_mode: false
  set include_erts: false
  set include_src: false
  set cookie: cookie
  set overlays: [
    {:template, "rel/templates/vm.args.eex", "releases/<%= release_version %>/vm.args"}
  ]
end

release :gateway do
  set version: current_version(:gateway)
  set applications: [
    gateway: :permanent
  ]
end
