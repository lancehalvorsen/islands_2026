defmodule IslandsEngine.GameSupervisorTest do
  use ExUnit.Case, async: true

  alias IslandsEngine.Game
  alias IslandsEngine.GameSupervisor

  describe "start_game/1" do
    test "starts a new game" do
      name = "Dweezil"
      via = Game.via_tuple(name)

      assert nil == GenServer.whereis(via)
      {:ok, game} = GameSupervisor.start_game(name)

      assert is_pid(game)
      assert game == GenServer.whereis(via)
    end
  end

  describe "stop_game/1" do
    test "stops a running game" do
      name = "Frank"
      via = Game.via_tuple(name)

      {:ok, game} = GameSupervisor.start_game(name)
      assert is_pid(game)
      assert game == GenServer.whereis(via)

      :ok = GameSupervisor.stop_game(name)
      assert nil == GenServer.whereis(via)
    end
  end
end
