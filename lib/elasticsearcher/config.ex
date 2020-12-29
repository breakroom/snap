defmodule Elasticsearcher.Config do
  use GenServer

  def start_link({name, config}) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  ## Callbacks

  def init(config) do
    {:ok, config}
  end

  def handle_call(:get, _from, config) do
    {:reply, config, config}
  end
end
