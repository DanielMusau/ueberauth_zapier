defmodule Ueberauth.Strategy.Zapier do
  @moduledoc """
  Implements an Überauth strategy for authentication with Zapier.

  When configuring the strategy in the Überauth provides, you can specify some defaults.

  * `default_scope` - The default scopes to request from Zapier when authenticating. Default `zap zap:write authentication profile`.
  * `oauth2_module` - The OAuth2 module to use for authentication. Default `Ueberauth.Strategy.Zapier.OAuth`.

  ```elixir

  config :ueberauth, Ueberauth,
    providers: [
      zapier: {Ueberauth.Strategy.Zapier, [default_scope: "zap zap:write authentication profile"]}
    ]
  ```
  """

  use Ueberauth.Strategy,
    oauth2_module: Ueberauth.Strategy.Zapier.OAuth,
    default_scope: "zap zap:write authentication profile"

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Auth.Credentials

  @doc """
  Handles initial redirect to the Zapier OAuth authorization page.

  To customize the scopes, set the `:default_scope` option in your configuration.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)

    params =
      [scope: scopes]
      |> with_state_param(conn)

    opts = oauth_client_options_from_conn(conn)
    redirect!(conn, Ueberauth.Strategy.Zapier.OAuth.authorize_url!(params, opts))
  end

  @doc """
  Handles the callback from Zapier.

  When there is a failure from Zapier the failure is included in the `ueberauth_failure` struct. Otherwise the information returned from Patreon is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    params = [code: code]
    opts = oauth_client_options_from_conn(conn)

    case Ueberauth.Strategy.Zapier.OAuth.get_access_token(params, opts) do
      {:ok, token} ->
        fetch_user(conn, token)

      {:error, {error, description}} ->
        set_errors!(conn, [error(error, description)])
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw response during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:zapier_token, nil)
    |> put_private(:zapier_user, nil)
  end

  @doc """
  Fetches the uid field from the Zapier response.
  """
  def uid(conn) do
    uid_field =
      conn
      |> option(:uid_field)
      |> to_string()

    conn.private.zapier_user[uid_field]
  end

  @doc """
  Includes the credentials from the Zapier response.
  """
  def credentials(conn) do
    token = conn.private.zapier_token
    scope_string = token.other_params["scope"] || ""
    scopes = String.split(scope_string, ",")

    %Credentials{
      token: token.access_token,
      token_type: token.token_type,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      expires: !!token.expires_at,
      scopes: scopes
    }
  end

  @doc """
  Fetches the user information from the Zapier response to populate the `Ueberauth.Auth.Info` struct.
  """
  def info(conn) do
    user = conn.private.zapier_user

    %Info{
      email: user["email"],
      first_name: user["first_name"],
      last_name: user["last_name"]
    }
  end

  @doc """
  Stores the raw information (including the token and user) in the `Ueberauth.Auth.Extra` struct.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.zapier_token,
        user: conn.private.zapier_user
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :zapier_token, token)

    resp = Ueberauth.Strategy.Zapier.OAuth.get(token, "https://api.zapier.com/v1/profiles/me")

    case resp do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: user}}
      when status_code in 200..399 ->
        put_private(conn, :zapier_user, user)

      {:error, %OAuth2.Response{status_code: status_code}} ->
        set_errors!(conn, [error("OAuth2", status_code)])

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])

      {:error, _} ->
        set_errors!(conn, [error("OAuth2", "unknown error")])
    end
  end

  defp oauth_client_options_from_conn(conn) do
    base_options = [redirect_uri: callback_url(conn)]
    request_options = conn.private[:ueberauth_request_options].options

    case {request_options[:client_id], request_options[:client_secret]} do
      {nil, _} -> base_options
      {_, nil} -> base_options
      {id, secret} -> [client_id: id, client_secret: secret] ++ base_options
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn) || [], key, Keyword.get(default_options(), key))
  end
end
