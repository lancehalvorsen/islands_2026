defmodule IslandsEngine.GameSupervisor do
  use DynamicSupervisor

  alias IslandsEngine.Game
  alias IslandsEngine.GameSupervisor

  def start_link(_options),
    do: DynamicSupervisor.start_link(GameSupervisor, :ok, name: GameSupervisor)

  def start_game(name), do: DynamicSupervisor.start_child(GameSupervisor, {Game, name})

  def stop_game(name) do
    :ets.delete(:game_state, name)
    DynamicSupervisor.terminate_child(GameSupervisor, pid_from_name(name))
  end

  @impl true
  def init(_init_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp pid_from_name(name) do
    name
    |> Game.via_tuple()
    |> GenServer.whereis()
  end
end
