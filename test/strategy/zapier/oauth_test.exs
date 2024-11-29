defmodule Ueberauth.Strategy.Zapier.OAuthTest do
  use ExUnit.Case, async: true

  alias Ueberauth.Strategy.Zapier.OAuth

  defmodule MyApp.Zapier do
    def client_secret(_opts), do: "test_client_secret"
  end

  describe "client/1" do
    test "uses client secret in the config when it is not a tuple" do
      assert %OAuth2.Client{client_secret: "client_secret"} = OAuth.client()
    end

    test "generates client secret when it is using a tuple config" do
      options = [client_secret: {MyApp.Zapier, :client_secret}]
      assert %OAuth2.Client{client_secret: "test_client_secret"} = OAuth.client(options)
    end
  end
end
