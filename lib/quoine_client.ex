defmodule QuoineClient do
  @endpoint "https://api.quoine.com"
  @type http_method :: :get | :post | :put | :delete
  @spec request(http_method, String.t(), keyword()) :: any()
  def request(method, path, options \\ []) when method in [:get, :post, :put, :delete] do
    token_id = options[:token_id]
    secret = options[:secret]

    params = options[:params]
    body = if params, do: Poison.encode!(params), else: ""

    auth_headers =
      if token_id && secret do
        signature =
          %{
            path: path,
            nonce: System.system_time(:milliseconds),
            token_id: token_id
          }
          |> Joken.token()
          |> Joken.sign(Joken.hs256(secret))
          |> Joken.get_compact()

        [{"X-Quoine-Auth", signature}]
      else
        []
      end

    headers = [
      {"Content-Type", "application/json"},
      {"X-Quoine-API-Version", "2"}
    ] ++ auth_headers

    url = @endpoint <> path

    HTTPoison.request(method, url, body, headers)
    |> case do
         {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:ok, Poison.decode!(body)}
         {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code in [400, 422, 503] -> {:error, Poison.decode!(body)}
         {:ok, %HTTPoison.Response{status_code: 404}} -> {:error, :not_found}
         {:ok, %HTTPoison.Response{status_code: 401}} -> {:error, :unauthorized}
         {:ok, %HTTPoison.Response{status_code: 429}} -> {:error, :too_many_requests}
       end

  end
end
