import Config

config :ueberauth, Ueberauth,
  providers: [
    zapier: {UeberauthZapier, [default_scope: "zap zap:write authentication profile"]}
  ]

config :ueberauth, Ueberauth.Strategy.Zapier.OAuth,
  client_id: "client_id",
  client_secret: "client_secret",
  token_url: "token_url"
