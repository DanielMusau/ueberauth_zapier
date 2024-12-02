# Überauth Zapier

[![Hex.pm](https://img.shields.io/hexpm/v/ueberauth_zapier.svg)](https://hex.pm/packages/ueberauth_zapier)
[![Documentation](https://img.shields.io/badge/hex-docs-blue)](https://hexdocs.pm/ueberauth_zapier)

> Ueberauth plugin for Zapier OAuth.

## What is this?
[Ueberauth](https://github.com/ueberauth/ueberauth) is an authentication framework for Elixir applications that specializes in [OAuth](https://oauth.net/). This library is one of many [plugins](https://github.com/ueberauth/ueberauth/wiki/List-of-Strategies) (called Strategies) that allow Ueberauth to integrate with different identity providers. Specifically, this one implements an OAuth integration with Zapier.

## Installation

1. Setup your application integration in Zapier Development Dashboard https://developer.zapier.com/

2. Add `:ueberauth_zapier` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [
        {:ueberauth, "~> 0.10"},
        {:oauth2, "~> 2.1"},
        {:ueberauth_zapier, "~> 0.1.1"}
      ]
    end
    ```

3. Add Zapier to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        # Configure Zapier OAuth strategy with 'profile' scope to get user profile.
        # Additional scopes can be added as needed, separated by spaces
        zapier: {Ueberauth.Strategy.Zapier, [default_scope: "profile"]},
      ]
    ```

4.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Zapier.OAuth,
      client_id: System.get_env("ZAPIER_CLIENT_ID"),
      client_secret: System.get_env("ZAPIER_CLIENT_SECRET")
    ```

5.  Include the Überauth plug in your router pipeline:

    ```elixir
    defmodule TestZapierWeb.Router do
      use TestZapierWeb, :router

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

6.  Add the request and callback routes:

    ```elixir
    scope "/auth", TestZapierWeb do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

7. Create a new controller or use an existing controller that implements callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses from Zapier.

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