# Überauth Zapier

[![Hex Version](https://img.shields.io/hexpm/v/ueberauth_zapier.svg)](https://hex.pm/packages/ueberauth_zapier)

> Zapier OAuth2 strategy for Überauth.

## Installation

1. Setup your application ntegration in Zapier Development Dashboard https://developer.zapier.com/

1. Add `:ueberauth_zapier` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_zapier, "~> 0.1.0"}]
    end
    ```

1. Add Zapier to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        zapier: {Ueberauth.Strategy.Zapier, [default_scope: "profile"]},
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Zapier.OAuth,
      client_id: System.get_env("ZAPIER_CLIENT_ID"),
      client_secret: System.get_env("ZAPIER_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your router pipeline:

    ```elixir
    defmodule TestZapierWeb.Router do
      use TestZapierWeb, :router

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

1.  Add the request and callback routes:

    ```elixir
    scope "/auth", TestZapierWeb do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Create a new controller or use an existing controller that implements callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses from Zapier.

    ```elixir
      defmodule TestZapierWeb.AuthController do
        use TestZapierWeb, :controller

        def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
          conn
          |> put_flash(:error, "Failed to authenticate.")
          |> redirect(to: "/")
        end

        def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
          case UserFromAuth.find_or_create(auth) do
            {:ok, user} ->
              conn
              |> put_flash(:info, "Successfully authenticated.")
              |> put_session(:current_user, user)
              |> configure_session(renew: true)
              |> redirect(to: "/")

            {:error, reason} ->
              conn
              |> put_flash(:error, reason)
              |> redirect(to: "/")
          end
        end
      end
    ```

## Calling

Once your setup, you can initiate auth using the following URL, unless you changed the routes from the guide:

    /auth/zapier

## Documentation

The docs can be found at [ueberauth_zapier][package-docs] on [Hex Docs][hex-docs].

[hex-docs]: https://hexdocs.pm
[package-docs]: https://hexdocs.pm/ueberauth_zapier