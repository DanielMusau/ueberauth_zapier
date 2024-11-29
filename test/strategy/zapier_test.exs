defmodule Ueberauth.Strategy.ZapierTest do
  use ExUnit.Case, async: false
  use Plug.Test

  import Plug.Conn

  doctest UeberauthZapier

  def set_options(routes, conn, opt) do
    case Enum.find_index(routes, &(elem(&1, 0) == {conn.request_path, conn.method})) do
      nil ->
        routes

      idx ->
        update_in(routes, [Access.at(idx), Access.elem(1), Access.elem(2)], &%{&1 | options: opt})
    end
  end

  test "calls handle_request! using settings in the config" do
    conn =
      conn(:get, "/auth/zapier", %{
        client_id: "12345",
        client_secret: "98765",
        redirect_uri: "http://localhost:4000/auth/zapier/callback"
      })

    routes = Ueberauth.init()

    resp = Ueberauth.call(conn, routes)

    assert resp.status == 302
    assert [location] = get_resp_header(resp, "location")

    redirect_uri = URI.parse(location)
    assert redirect_uri.host == "zapier.com"
    assert redirect_uri.path == "/oauth2/authorize"

    assert %{
             "client_id" => "test_client_id",
             "response_type" => "code",
             "scope" => "profile"
           } = Plug.Conn.Query.decode(redirect_uri.query)
  end
end
