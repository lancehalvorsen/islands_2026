defmodule IslandsEngine.Game do
  use GenServer

  alias IslandsEngine.Board
  alias IslandsEngine.Coordinate
  alias IslandsEngine.Guesses
  alias IslandsEngine.Island
  alias IslandsEngine.Rules

  @players [:player1, :player2]
  @timeout 60 * 60 * 1000

  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def via_tuple(name) do
    {:via, Registry, {Registry.Game, name}}
  end

  def demo_call(game) do
    GenServer.call(game, :demo_call)
  end

  def demo_cast(game, test_value) do
    GenServer.cast(game, {:demo_cast, test_value})
  end

  def add_player(game, name) when is_binary(name) do
    GenServer.call(game, {:add_player, name})
  end

  def position_island(game, player, key, row, col) when player in @players do
    GenServer.call(game, {:position_island, player, key, row, col})
  end

  def set_islands(game, player) when player in @players do
    GenServer.call(game, {:set_islands, player})
  end

  def guess_coordinate(game, player, row, col) when player in @players do
    GenServer.call(game, {:guess_coordinate, player, row, col})
  end

  def init(name) do
    state = fresh_state(name)
    {:ok, state, {:continue, {:init, name}}}
  end

  def terminate({:shutdown, :timeout}, state_data) do
    :ets.delete(:game_state, state_data.player1.name)
    :ok
  end

  def terminate(_reason, _state), do: :ok

  def handle_continue({:init, name}, _state) do
    state_data =
      case :ets.lookup(:game_state, name) do
        [] -> fresh_state(name)
        [{_key, state}] -> state
      end

    :ets.insert(:game_state, {name, state_data})
    {:noreply, state_data, @timeout}
  end

  def handle_info(:timeout, state_data) do
    {:stop, {:shutdown, :timeout}, state_data}
  end

  def handle_info(:first, state) do
    IO.puts("This message has been handled by handle_info/2, matching on :first.")
    {:noreply, state}
  end

  def handle_cast({:demo_cast, new_value}, state) do
    {:noreply, Map.put(state, :test, new_value)}
  end

  def handle_call(:demo_call, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:add_player, name}, _from, game_state) do
    with {:ok, rules} <- Rules.check(game_state.rules, :add_player) do
      game_state
      |> update_player2_name(name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, game_state}
    end
  end

  def handle_call({:position_island, player, key, row, col}, _from, game_state) do
    board = player_board(game_state, player)

    with {:ok, rules} <-
           Rules.check(game_state.rules, {:position_islands, player}),
         {:ok, coordinate} <-
           Coordinate.new(row, col),
         {:ok, island} <-
           Island.new(key, coordinate),
         %{} = board <-
           Board.position_island(board, key, island) do
      game_state
      |> update_board(player, board)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error ->
        {:reply, :error, game_state}

      {:error, :invalid_coordinate} ->
        {:reply, {:error, :invalid_coordinate}, game_state}

      {:error, :invalid_island_type} ->
        {:reply, {:error, :invalid_island_type}, game_state}
    end
  end

  def handle_call({:set_islands, player}, _from, game_state) do
    board = player_board(game_state, player)

    with {:ok, rules} <- Rules.check(game_state.rules, {:set_islands, player}),
         true <- Board.all_islands_positioned?(board) do
      game_state
      |> update_rules(rules)
      |> reply_success({:ok, board})
    else
      :error -> {:reply, :error, game_state}
      false -> {:reply, {:error, :not_all_islands_positioned}, game_state}
    end
  end

  def handle_call({:guess_coordinate, player_key, row, col}, _from, game_state) do
    opponent_key = opponent(player_key)
    opponent_board = player_board(game_state, opponent_key)

    with {:ok, rules} <-
           Rules.check(game_state.rules, {:guess_coordinate, player_key}),
         {:ok, coordinate} <-
           Coordinate.new(row, col),
         {hit_or_miss, forested_island, win_status, opponent_board} <-
           Board.guess(opponent_board, coordinate),
         {:ok, rules} <-
           Rules.check(rules, {:win_check, win_status}) do
      game_state
      |> update_board(opponent_key, opponent_board)
      |> update_guesses(player_key, hit_or_miss, coordinate)
      |> update_rules(rules)
      |> reply_success({hit_or_miss, forested_island, win_status})
    else
      :error ->
        {:reply, :error, game_state}

      {:error, :invalid_coordinate} ->
        {:reply, {:error, :invalid_coordinate}, game_state}
    end
  end

  defp fresh_state(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    %{player1: player1, player2: player2, rules: %Rules{}}
  end

  defp player_board(game_state, player), do: Map.get(game_state, player).board

  defp opponent(:player1), do: :player2
  defp opponent(:player2), do: :player1

  defp update_player2_name(game_state, name) do
    put_in(game_state.player2.name, name)
  end

  defp update_board(game_state, player, board) do
    Map.update!(game_state, player, fn player -> %{player | board: board} end)
  end

  defp update_rules(game_state, rules) do
    %{game_state | rules: rules}
  end

  defp update_guesses(game_state, player_key, hit_or_miss, coordinate) do
    update_in(game_state[player_key].guesses, fn guesses ->
      Guesses.add(guesses, hit_or_miss, coordinate)
    end)
  end

  defp reply_success(game_state, reply) do
    {:reply, reply, game_state}
  end
end
