defmodule Goofy.Server do
  use Slack

  def init(initial_state, slack) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, initial_state}
  end

  def handle_message(message = %{type: "message"}, slack, state) do
    id = "@" <> slack.me.id
    [mention | cmd] = String.split(message.text, " ")
    if Regex.match?(~r/<#{id}>/, mention) do
      handle_command(cmd, message, slack, state)
      {:ok, state}
    end
    {:ok, state}
  end

  def handle_message(_message, _slack, state) do
    {:ok, state}
  end

  defp handle_command(["set", key, val], message, slack, _state) do
    client = Exredis.start
    # Extract value from encoding <img>
    message_to_send = case Regex.named_captures(~r/<(?<src>.*)>/, val) do
        %{"src" => src} -> (
          client |> Exredis.query ["set", key, src]
          ~s("Set #{key} to #{val}")
        )
        _ -> ~s("Found invalid value: #{val}")
    end
    send_message(message_to_send, message.channel, slack)
  end

  defp handle_command([ val | [] ], message, slack, state) do
    token = state.token
    conn_str = "redis://" <> state.redis_host <> ":" <> state.redis_port
    client = Exredis.start_using_connection_string(conn_str)
    case client |> Exredis.query ["get", val] do
      :undefined -> send_message(~s("Cannot find #{val}"), message.channel, slack)
      img_url -> (
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
        HTTPoison.post(state.hook_url, JSX.encode!(query))
      )
    end
    client |> Exredis.stop
  end

  def terminate(reason, state) do
    IO.inspect reason
    start_link(state.token, state)
  end

end
