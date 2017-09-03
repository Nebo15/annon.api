use Mix.Releases.Config,
  default_release: :default,
  default_environment: :default

environment :default do
  set pre_start_hook: "bin/hooks/pre-start.sh"
  set dev_mode: false
  set include_erts: false
  set include_src: false
  set overlays: [
    {:template, "rel/templates/vm.args.eex", "releases/<%= release_version %>/vm.args"}
  ]
  set commands: [
    migrate: "rel/commands/migrate.sh"
  ]
  # The cookie is set at start time by ERLANG_COOKIE environment variable,
  # but we want to suppress Distillery warnings
  set cookie: :nowarn
end

release :annon_api do
  set version: current_version(:annon_api)
  set applications: [
    annon: :permanent
  ]
end
