defmodule Goofy.Server do
  use Slack
  @table_name :goofy

  def init(initial_state, slack) do
    IO.puts "Connected as #{slack.me.name}"
    cache_pid = :erlang.whereis Cache
    IO.puts "ADding PID #{cache_pid}"
    {:ok, Map.put(initial_state, :cache_pid, cache_pid)}
  end

  def handle_message(message = %{type: "message"}, slack, state) do
    id = "@" <> slack.me.id
    IO.puts "Message: #{message.text}"
    [mention | cmd] = String.split(message.text, " ")
    cache_pid = :erlang.whereis Cache
    state = Map.put(state, :cache_pid, cache_pid)
    if Regex.match?(~r/<#{id}>/, mention) do
      IO.puts "Got message:"
      IO.inspect cmd
      handle_command(cmd, message, slack, state)
      {:ok, state}
    end
    {:ok, state}
  end

  def handle_message(_message, _slack, state) do
    {:ok, state}
  end

  defp handle_command(["set", key, val], message, slack, state) do
    # Extract value from encoding <img>
    IO.puts "Setting #{key} to #{val}"
    cache_pid = state[:cache_pid]
    message_to_send = case Regex.named_captures(~r/<(?<src>.*)>/, val) do
        %{"src" => src} -> (
          IO.puts "Adding #{key} to #{src}"
          ~s("Set #{key} to #{val}")
          case Cache.put(cache_pid, key, src) do
            true ->
              ~s("Set #{key} to #{val}")
            false -> ~s("Could not add gif")
          end
        )
        _ -> ~s("Found invalid value: #{val}")
    end
    send_message(message_to_send, message.channel, slack)
  end

  # defp handle_command(["search", key], message, slack, state) do
  #   conn_str = "redis://" <> state.redis_host <> ":" <> state.redis_port
  #   client = Exredis.start_using_connection_string(conn_str)
  #   keys = client |> Exredis.query ["keys", key <> "*"]
  #   query = %{
  #     id: slack.me.id,
  #     token: state.token,
  #     channel: message.user,
  #     username: state.username
  #   }
  #   Enum.each(keys, fn key -> send_hook_message(state.hook_url, Dict.put(query, "text", key)) end)
  #   client |> Exredis.stop
  # end

  defp handle_command([ val | [] ], message, slack, state) do
    token = state.token
    IO.puts "Getting #{val}"
    case Cache.get(val) do
      :error ->
        IO.puts "can't find #{val}"
        send_message(~s("Cannot find #{val}"), message.channel, slack)
      { :ok, img_url } -> (
        IO.puts "Found #{img_url}"
        query = %{
          id: slack.me.id,
          token: token,
          text: val,
          channel: message.channel,
          attachments: [
            %{image_url: img_url}
          ],
          username: state.username
        }
        send_hook_message(state.hook_url, query)
      )
    end
  end

  def send_hook_message(hook_url, query) do
    HTTPoison.post(hook_url, JSX.encode!(query))
  end

  def terminate(reason, state) do
    IO.inspect reason
    start_link(state.token, state)
  end

end
