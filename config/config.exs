import Config

version = Mix.Project.config()[:version]

config :mirego_elixir_boilerplate,
  ecto_repos: [MiregoElixirBoilerplate.Repo],
  version: version

config :phoenix, :json_library, Jason

config :mirego_elixir_boilerplate, MiregoElixirBoilerplateWeb.Endpoint,
  pubsub_server: MiregoElixirBoilerplate.PubSub,
  render_errors: [view: MiregoElixirBoilerplateWeb.Errors.View, accepts: ~w(html json)]

config :mirego_elixir_boilerplate, MiregoElixirBoilerplate.Repo, start_apps_before_migration: [:ssl]

config :mirego_elixir_boilerplate, Corsica, allow_headers: :all

config :mirego_elixir_boilerplate, MiregoElixirBoilerplate.Gettext, default_locale: "en"

config :mirego_elixir_boilerplate, MiregoElixirBoilerplateWeb.ContentSecurityPolicy, allow_unsafe_scripts: false

config :sentry,
  root_source_code_path: File.cwd!(),
  release: version

config :logger, backends: [:console, Sentry.LoggerBackend]

# Import environment configuration
import_config "#{Mix.env()}.exs"
