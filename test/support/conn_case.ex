defmodule Annon.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  ## Credentials

  Most of source code is a copy-paste from `Phoenix.ConnTest`,
  it's already contains great tests suite, but we don't
  want to depend on Phoenix.

  ## Endpoint testing

  `Annon.ConnCase` typically works against routers. That's
  the preferred way to test anything that your router dispatches
  to.

      conn = get build_conn(), "/"
      assert conn.resp_body =~ "Welcome!"

      conn = post build_conn(), "/login", [username: "john", password: "doe"]
      assert conn.resp_body =~ "Logged in!"

  As in your application, the connection is also the main abstraction
  in testing. `build_conn()` returns a new connection and functions in this
  module can be used to manipulate the connection before dispatching
  to the router.

  For example, one could set the accepts header for json requests as
  follows:

      build_conn()
      |> put_req_header("accept", "application/json")
      |> get("/")

  The router being tested is accessed via the `@router` module
  attribute.

  ## Controller testing

  The functions in this module can also be used for controller
  testing. While router testing is preferred over controller
  testing as a controller often depends on the pipelines invoked
  in the router and before, unit testing controllers may be helpful
  in some situations.

  For such cases, just pass an atom representing the action
  to dispatch:

      conn = get build_conn(), :index
      assert conn.resp_body =~ "Welcome!"

  """
  use ExUnit.CaseTemplate
  import ExUnit.Assertions, only: [flunk: 1]
  alias Plug.Conn

  using(conf) do
    quote bind_quoted: [conf: conf] do
      # Import conveniences for testing with connections
      import Annon.ConnCase
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Plug.Conn
      import Annon.PathHelpers
      alias Annon.Configuration.Repo, as: ConfigurationRepo
      alias Annon.Requests.Repo, as: RequestsRepo
      alias Plug.Conn

      # The default router for testing
      @router Keyword.get(conf, :router, Annon.ManagementAPI.Router)
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Annon.Configuration.Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Annon.Requests.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Annon.Configuration.Repo, {:shared, self()})
      Ecto.Adapters.SQL.Sandbox.mode(Annon.Requests.Repo, {:shared, self()})
    end

    conn =
      Annon.ConnCase.build_conn()
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.assign(:upstream_request, %Annon.Plugin.UpstreamRequest{})

    {:ok, conn: conn}
  end

  @doc """
  Creates a connection to be used in upcoming requests.
  """
  @spec build_conn() :: Conn.t
  def build_conn do
    build_conn(:get, "/", nil)
  end

  @doc """
  Deprecated version of conn/0. Use build_conn/0 instead
  """
  @spec conn() :: Conn.t
  def conn do
    IO.write :stderr, """
    warning: using conn/0 to build a connection is deprecated. Use build_conn/0 instead.
    #{Exception.format_stacktrace}
    """
    build_conn()
  end

  @doc """
  Creates a connection to be used in upcoming requests
  with a preset method, path and body.

  This is useful when a specific connection is required
  for testing a plug or a particular function.
  """
  @spec build_conn(atom | binary, binary, binary | list | map) :: Conn.t
  def build_conn(method, path, params_or_body \\ nil) do
    %Conn{}
    |> Plug.Adapters.Test.Conn.conn(method, path, params_or_body)
    |> Conn.put_private(:plug_skip_csrf_protection, true)
  end

  @http_methods [:get, :post, :put, :patch, :delete, :options, :connect, :trace, :head]
  @http_json_methods [:post, :put, :patch]

  for method <- @http_methods do
    @doc """
    Dispatches to the current router.

    See `dispatch/5` for more information.
    """
    defmacro unquote(method)(conn, path_or_action, params_or_body \\ nil) do
      method = unquote(method)
      quote do
        Annon.ConnCase.dispatch(unquote(conn), @router, unquote(method),
                                unquote(path_or_action), unquote(params_or_body))
      end
    end
  end

  for method <- @http_json_methods do
    json_method = String.to_atom(Atom.to_string(method) <> "_json")
    @doc """
    Dispatches to the current router with JSON-encoded params.

    See `dispatch/5` for more information.
    """
    defmacro unquote(json_method)(conn, path_or_action, params) do
      method = unquote(method)
      quote do
        params = Poison.encode!(unquote(params))
        Annon.ConnCase.dispatch(unquote(conn), @router, unquote(method),
                                unquote(path_or_action), params)
      end
    end
  end


  @doc """
  Dispatches the connection to the given router.

  When invoked via `get/3`, `post/3` and friends, the router
  is automatically retrieved from the `@router` module
  attribute, otherwise it must be given as an argument.

  The connection will be configured with the given `method`,
  `path_or_action` and `params_or_body`.

  If `path_or_action` is a string, it is considered to be the
  request path and stored as so in the connection. If an atom,
  it is assumed to be an action and the connection is dispatched
  to the given action.

  ## Parameters and body

  This function, as well as `get/3`, `post/3` and friends, accepts the
  request body or parameters as last argument:

        get build_conn(), "/", some: "param"
        get build_conn(), "/", "some=param&url=encoded"

  The allowed values are:

    * `nil` - meaning there is no body

    * a binary - containing a request body. For such cases, `:headers`
      must be given as option with a content-type

    * a map or list - containing the parameters which will automatically
      set the content-type to multipart. The map or list may contain
      other lists or maps and all entries will be normalized to string
      keys

    * a struct - unlike other maps, a struct will be passed through as-is
      without normalizing its entries
  """
  def dispatch(conn, router, method, path_or_action, params_or_body \\ nil)
  def dispatch(%Plug.Conn{} = conn, router, method, path_or_action, params_or_body) do
    if is_nil(router) do
      raise "no @router set in test case"
    end

    if is_binary(params_or_body) and is_nil(List.keyfind(conn.req_headers, "content-type", 0)) do
      raise ArgumentError, "a content-type header is required when setting " <>
                           "a binary body in a test connection"
    end

    conn
    |> dispatch_router(router, method, path_or_action, params_or_body)
    |> from_set_to_sent()
  end
  def dispatch(conn, _router, method, _path_or_action, _params_or_body) do
    raise ArgumentError, "expected first argument to #{method} to be a " <>
                         "%Plug.Conn{}, got #{inspect conn}"
  end

  defp dispatch_router(conn, router, method, path, params_or_body) when is_binary(path) do
    conn
    |> Plug.Adapters.Test.Conn.conn(method, path, params_or_body)
    |> router.call(router.init([]))
  end

  defp dispatch_router(conn, router, method, action, params_or_body) when is_atom(action) do
    conn
    |> Plug.Adapters.Test.Conn.conn(method, "/", params_or_body)
    |> router.call(router.init(action))
  end

  defp from_set_to_sent(%Conn{state: :set} = conn),
    do: Conn.send_resp(conn)
  defp from_set_to_sent(conn),
    do: conn

  @doc """
  Puts a request cookie.
  """
  @spec put_req_cookie(Conn.t, binary, binary) :: Conn.t
  defdelegate put_req_cookie(conn, key, value), to: Plug.Test

  @doc """
  Deletes a request cookie.
  """
  @spec delete_req_cookie(Conn.t, binary) :: Conn.t
  defdelegate delete_req_cookie(conn, key), to: Plug.Test

  @doc """
  Returns the content type as long as it matches the given format.

  ## Examples

      # Assert we have an html response with utf-8 charset
      assert response_content_type(conn, :html) =~ "charset=utf-8"

  """
  @spec response_content_type(Conn.t, atom) :: String.t | no_return
  def response_content_type(conn, format) when is_atom(format) do
    case Conn.get_resp_header(conn, "content-type") do
      [] ->
        raise "no content-type was set, expected a #{format} response"
      [h] ->
        if response_content_type?(h, format) do
          h
        else
          raise "expected content-type for #{format}, got: #{inspect h}"
        end
      [_|_] ->
        raise "more than one content-type was set, expected a #{format} response"
    end
  end

  defp response_content_type?(header, format) do
    case parse_content_type(header) do
      {part, subpart} ->
        format = Atom.to_string(format)
        format in MIME.extensions(part <> "/" <> subpart) or
          format == subpart or String.ends_with?(subpart, "+" <> format)
      _  ->
        false
    end
  end

  defp parse_content_type(header) do
    case Plug.Conn.Utils.content_type(header) do
      {:ok, part, subpart, _params} ->
        {part, subpart}
      _ ->
        false
    end
  end

  @doc """
  Asserts the given status code and returns the response body
  if one was set or sent.

  ## Examples

      conn = get build_conn(), "/"
      assert response(conn, 200) =~ "hello world"

  """
  @spec response(Conn.t, status :: integer | atom) :: binary | no_return
  def response(%Conn{state: :unset}, _status) do
    raise """
    expected connection to have a response but no response was set/sent.
    Please verify that you assign to "conn" after a request:

        conn = get conn, "/"
        assert html_response(conn) =~ "Hello"
    """
  end

  def response(%Conn{status: status, resp_body: body}, given) do
    given = Plug.Conn.Status.code(given)

    if given == status do
      body
    else
      raise "expected response with status #{given}, got: #{status}, with body:\n#{body}"
    end
  end

  @doc """
  Asserts the given status code, that we have an html response and
  returns the response body if one was set or sent.

  ## Examples

      assert html_response(conn, 200) =~ "<html>"
  """
  @spec html_response(Conn.t, status :: integer | atom) :: String.t | no_return
  def html_response(conn, status) do
    body = response(conn, status)
    _    = response_content_type(conn, :html)
    body
  end

  @doc """
  Asserts the given status code, that we have an text response and
  returns the response body if one was set or sent.

  ## Examples

      assert text_response(conn, 200) =~ "hello"
  """
  @spec text_response(Conn.t, status :: integer | atom) :: String.t | no_return
  def text_response(conn, status) do
    body = response(conn, status)
    _    = response_content_type(conn, :text)
    body
  end

  @doc """
  Asserts the given status code, that we have an json response and
  returns the decoded JSON response if one was set or sent.

  ## Examples

      body = json_response(conn, 200)
      assert "can't be blank" in body["errors"]

  """
  @spec json_response(Conn.t, status :: integer | atom) :: map | no_return
  def json_response(conn, status, opts \\ []) do
    body = response(conn, status)
    _    = response_content_type(conn, :json)
    case Poison.decode(body, opts) do
      {:ok, body} ->
        body
      {:error, {:invalid, token, _}} ->
        raise "could not decode JSON body, invalid token #{inspect token} in body:\n\n#{body}"
      {:error, :invalid, _} ->
        raise "could not decode JSON body, body is empty"
    end
  end

  @doc """
  Returns the location header from the given redirect response.

  Raises if the response does not match the redirect status code
  (defaults to 302).

  ## Examples

      assert redirected_to(conn) =~ "/foo/bar"
      assert redirected_to(conn, 301) =~ "/foo/bar"
      assert redirected_to(conn, :moved_permanently) =~ "/foo/bar"
  """
  @spec redirected_to(Conn.t, status :: non_neg_integer) :: Conn.t
  def redirected_to(conn, status \\ 302)

  def redirected_to(%Conn{state: :unset}, _status) do
    raise "expected connection to have redirected but no response was set/sent"
  end

  def redirected_to(conn, status) when is_atom(status) do
    redirected_to(conn, Plug.Conn.Status.code(status))
  end

  def redirected_to(%Conn{status: status} = conn, status) do
    location = conn |> Conn.get_resp_header("location") |> List.first
    location || raise "no location header was set on redirected_to"
  end

  def redirected_to(conn, status) do
    raise "expected redirection with status #{status}, got: #{conn.status}"
  end

  @doc """
  Recycles the connection.

  Recycling receives a connection and returns a new connection,
  containing cookies and relevant information from the given one.

  This emulates behaviour performed by browsers where cookies
  returned in the response are available in following requests.

  Note `recycle/1` is automatically invoked when dispatching
  to the router, unless the connection has already been
  recycled.
  """
  @spec recycle(Conn.t) :: Conn.t
  def recycle(conn) do
    build_conn()
    |> Plug.Test.recycle_cookies(conn)
    |> copy_headers(conn.req_headers, ~w(accept))
  end

  defp copy_headers(conn, headers, copy) do
    headers = for {k, v} <- headers, k in copy, do: {k, v}
    %{conn | req_headers: headers ++ conn.req_headers}
  end

  @doc """
  Asserts an error was wrapped and sent with the given status.

  Useful for testing actions that you expect raise an error and have
  the response wrapped in an HTTP status, with content usually rendered
  by your MyApp.ErrorView.

  The function accepts a status either as an integer HTTP status or
  atom, such as `404` or `:not_found`. If an error is raised, a
  3-tuple of the wrapped response is returned matching the
  status, headers, and body of the response:

      {404, [{"content-type", "text/html"} | _], "Page not found"}

  ## Examples

      assert_error_sent :not_found, fn ->
        get build_conn(), "/users/not-found"
      end

      response = assert_error_sent 404, fn ->
        get build_conn(), "/users/not-found"
      end
      assert {404, [_h | _t], "Page not found"} = response
  """
  @spec assert_error_sent(integer | atom, function) :: {integer, list, term}
  def assert_error_sent(status_int_or_atom, func) do
    expected_status = Plug.Conn.Status.code(status_int_or_atom)
    discard_previously_sent()
    result =
      func
      |> wrap_request()
      |> receive_response(expected_status)

    discard_previously_sent()
    result
  end

  defp receive_response({:ok, conn}, expected_status) do
    if conn.state == :sent do
      flunk "expected error to be sent as #{expected_status} status, but response sent #{conn.status} without error"
    else
      flunk "expected error to be sent as #{expected_status} status, but no error happened"
    end
  end
  defp receive_response({:error, {exception, stack}}, expected_status) do
    receive do
      {ref, {^expected_status, headers, body}} when is_reference(ref) ->
        {expected_status, headers, body}

      {ref, {sent_status, _headers, _body}} when is_reference(ref) ->
        reraise ExUnit.AssertionError.exception("""
        expected error to be sent as #{expected_status} status, but got #{sent_status} from:

        #{Exception.format_banner(:error, exception)}
        """), stack

    after 0 ->
      reraise ExUnit.AssertionError.exception("""
      expected error to be sent as #{expected_status} status, but got an error with no response from:

      #{Exception.format_banner(:error, exception)}
      """), stack
    end
  end

  defp discard_previously_sent do
    receive do
      {ref, {_, _, _}} when is_reference(ref) -> discard_previously_sent()
      {:plug_conn, :sent}                     -> discard_previously_sent()
    after
      0 -> :ok
    end
  end

  defp wrap_request(func) do
    try do
      {:ok, func.()}
    rescue
      exception -> {:error, {exception, System.stacktrace()}}
    end
  end
end
