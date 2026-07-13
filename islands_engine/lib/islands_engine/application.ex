defmodule IslandsEngine.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Registry.Game},
      {DynamicSupervisor, name: IslandsEngine.GameSupervisor, strategy: :one_for_one}
    ]

    :ets.new(:game_state, [:public, :named_table])

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
