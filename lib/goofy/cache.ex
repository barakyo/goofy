defmodule Cache do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def init(initial_state) do
    gifs = :ets.new(:goofy, [:named_table])
    {:ok, gifs}
  end

  def get(key) do
    case :ets.lookup(:goofy, key) do
      [{^key, val}] -> {:ok, val}
      [] -> :error
    end
  end

  def put(pid, key, val) do
    GenServer.call(pid, {:put, key, val})
  end

  def handle_call({ :put, key, val }, _from, state) do
    case :ets.insert(:goofy, {key, val}) do
      true -> {:reply, true, state}
      false -> {:reply, false, state}
    end
  end

end
