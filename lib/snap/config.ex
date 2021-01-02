defmodule Snap.Config do
  @moduledoc false
  use Agent

  def start_link({name, config}) do
    Agent.start_link(fn -> config end, name: name)
  end

  def get(pid) do
    Agent.get(pid, & &1)
  end
end
