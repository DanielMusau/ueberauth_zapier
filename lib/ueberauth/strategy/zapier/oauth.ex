defmodule Ueberauth.Strategy.Zapier.OAuth do
  @moduledoc """
  OAuth2 for Zapier.

  This module defines the OAuth2 client and necessary functions to handle
  authorization and token retrieval for Zapier's OAuth2 authentication.

  Add `client_id` and `client_secret` to your configuration to use this strategy:

  ```elixir
  config :ueberauth, Ueberauth.Strategy.Zapier.OAuth,
    client_id: System.get_env("ZAPIER_CLIENT_ID"),
    client_secret: System.get_env("ZAPIER_CLIENT_SECRET")
  ```
  """

  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://zapier.com",
    authorize_url: "https://zapier.com/oauth/authorize",
    token_url: "https://zapier.com/oauth/token/"
  ]

  @doc """
  Construct a client for requests to Zapier.

  This will be setup automatically for you in `Ueberauth.Strategy.Zapier`.

  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    config =
      :ueberauth
      |> Application.fetch_env!(__MODULE__)
      |> check_credential(:client_id)
      |> check_credential(:client_secret)

    json_library = Ueberauth.json_library()

    @defaults
    |> Keyword.merge(config)
    |> Keyword.merge(opts)
    |> resolve_values()
    |> generate_secret()
    |> OAuth2.Client.new()
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth.

  No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.get(url, headers, opts)
  end

  def get_access_token(params \\ [], opts \\ []) do
    case opts |> client |> OAuth2.Client.get_token(params) do
      {:error, %OAuth2.Response{body: %{"error" => error}} = response} ->
        description = Map.get(response.body, "error_description", "")
        {:error, {error, description}}

      {:error, %OAuth2.Error{reason: reason}} ->
        {:error, {"error", to_string(reason)}}

      {:ok, %OAuth2.Client{token: %{access_token: nil} = token}} ->
        %{"error" => error, "error_description" => description} = token.other_params
        {:error, {error, description}}

      {:ok, %OAuth2.Client{token: token}} ->
        {:ok, token}
    end
  end

  # Strategy Callbacks
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param("grant_type", "authorization_code")
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  defp resolve_values(list) do
    for {key, value} <- list do
      {key, resolve_value(value)}
    end
  end

  defp resolve_value({m, f, a}) when is_atom(m) and is_atom(f), do: apply(m, f, a)
  defp resolve_value(v), do: v

  defp generate_secret(opts) do
    if is_tuple(opts[:client_secret]) do
      {module, fun} = opts[:client_secret]
      secret = apply(module, fun, [opts])
      Keyword.put(opts, :client_secret, secret)
    else
      opts
    end
  end

  defp check_credential(config, key) do
    check_config_key_exists(config, key)

    case Keyword.get(config, key) do
      value when is_binary(value) ->
        config

      {:system, env_key} ->
        case System.get_env(env_key) do
          nil ->
            raise "Missing environment variable #{inspect(env_key)}"

          value ->
            Keyword.put(config, key, value)
        end
    end
  end

  defp check_config_key_exists(config, key) when is_list(config) do
    unless Keyword.has_key?(config, key) do
      raise "Missing configuration key #{inspect(key)}"
    end

    config
  end

  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.Zapier is not a keyword list, as expected"
  end
end
