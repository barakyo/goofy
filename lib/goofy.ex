defmodule Goofy do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    config = Application.get_all_env(:goofy)
    initial_state = %{
      token: config[:token],
      hook_url: config[:hook_url],
      redis_host: config[:redis_host],
      redis_port: config[:redis_port],
      username: config[:username]
    }

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Goofy.Worker, [arg1, arg2, arg3])
      worker(Cache, [Cache]),
      worker(Goofy.Server, [initial_state.token, initial_state])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Goofy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
