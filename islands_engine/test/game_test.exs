defmodule IslandsEngine.GameTest do
  use ExUnit.Case, async: true

  alias IslandsEngine.Board
  alias IslandsEngine.Coordinate
  alias IslandsEngine.Game
  alias IslandsEngine.Island

  setup do
    {:ok, game} = Game.start_link("derp")

    %{game: game}
  end

  describe "start_link/1" do
    test "when given a binary argument" do
      name = "such a binary"
      {:ok, game} = Game.start_link(name)
      assert is_pid(game)

      game_state = :sys.get_state(game)
      assert is_map(game_state)

      assert game_state.rules.player1 == :islands_not_set
      assert game_state.rules.player2 == :islands_not_set
      assert game_state.rules.state == :initialized

      assert game_state.player1.name == name
      assert game_state.player1.guesses.hits == MapSet.new()
      assert game_state.player1.guesses.misses == MapSet.new()
      assert game_state.player1.board == %{}

      assert is_nil(game_state.player2.name)
      assert game_state.player2.guesses.hits == MapSet.new()
      assert game_state.player2.guesses.misses == MapSet.new()
      assert game_state.player2.board == %{}
    end

    test "when given an invalid argument" do
      assert_raise(FunctionClauseError, fn ->
        Game.start_link(7)
      end)
    end
  end

  describe "via_tuple/1" do
    test "returns the correct value" do
      name = "Dweezil"
      assert {:via, Registry, {Registry.Game, name}} == Game.via_tuple(name)
    end
  end

  describe "add_player/2" do
    test "when the second player has already been added", %{game: game} do
      game_state = :sys.get_state(game)

      assert is_nil(game_state.player2.name)

      name = "Frank"
      assert :ok = Game.add_player(game, name)

      updated_game_state = :sys.get_state(game)
      assert updated_game_state.player2.name == name

      assert :error == Game.add_player(game, "does not matter who")
    end

    test "when the second player has not yet been added", %{game: game} do
      game_state = :sys.get_state(game)
      assert is_nil(game_state.player2.name)

      name = "Frank"
      assert :ok = Game.add_player(game, name)

      updated_game_state = :sys.get_state(game)
      assert updated_game_state.player2.name == name
    end
  end

  describe "position_island/4" do
    test "when the second player has joined", %{game: game} do
      :ok = Game.add_player(game, "Dweezil")
      assert :ok == Game.position_island(game, :player1, :dot, 1, 1)
    end

    test "when the state something besides :players_set", %{game: game} do
      assert :error == Game.position_island(game, :player1, :dot, 1, 1)
    end
  end

  describe "set_islands/2" do
    setup %{game: game} do
      :ok = Game.add_player(game, "Moon")
      %{game: game}
    end

    test "when neither player has placed any islands", %{game: game} do
      assert {:error, :not_all_islands_positioned} = Game.set_islands(game, :player1)
    end

    test "when the player trying to set their islands has placed them all", %{game: game} do
      populate_board(game, :player1)
      assert {:ok, _board} = Game.set_islands(game, :player1)
    end

    test "when the player trying to set their islands has not placed them all", %{game: game} do
      populate_board(game, :player1)
      assert {:error, :not_all_islands_positioned} = Game.set_islands(game, :player2)
    end

    test "when both players have placed all their islands", %{game: game} do
      :ok = populate_board(game, :both)
      assert {:ok, _board} = Game.set_islands(game, :player1)
      assert {:ok, _board} = Game.set_islands(game, :player2)
    end
  end

  describe "guess_coordinate/4" do
    setup %{game: game} do
      :ok = Game.add_player(game, "Diva")
      :ok = populate_board(game, :both)
      {:ok, _board} = Game.set_islands(game, :player1)
      {:ok, _board} = Game.set_islands(game, :player2)
      %{game: game}
    end

    test "when it is not the player's turn", %{game: game} do
      assert :error = Game.guess_coordinate(game, :player2, 5, 5)
    end

    test "when it is the player's turn, but the guess is a miss", %{game: game} do
      assert {:miss, :none, :no_win} = Game.guess_coordinate(game, :player1, 5, 5)
    end

    test "when it is the player's turn, and the guess is a hit, but doesn't forest an island", %{
      game: game
    } do
      assert {:hit, :none, :no_win} = Game.guess_coordinate(game, :player1, 1, 1)
    end

    test "when it is the player's, guess is a hit, island is forested, but did not win the game",
         %{
           game: game
         } do
      assert {:hit, :dot, :no_win} = Game.guess_coordinate(game, :player1, 10, 10)
    end

    test "when it is the player's, guess is a hit, island is forested, and did win the game",
         %{
           game: game
         } do
      game_state = :sys.get_state(game)

      nearly_forested_board =
        game_state.player2.board
        |> forest_island(:atoll)
        |> forest_island(:l_shape)
        |> forest_island(:s_shape)
        |> forest_island(:square)

      :sys.replace_state(game, fn game_state ->
        put_in(game_state.player2.board, nearly_forested_board)
      end)

      assert {:hit, :dot, :win} = Game.guess_coordinate(game, :player1, 10, 10)
    end
  end

  defp populate_board(game, player) do
    :sys.replace_state(game, fn game_state ->
      case player do
        :player1 ->
          put_in(game_state.player1.board, full_island_set())

        :player2 ->
          put_in(game_state.player2.board, full_island_set())

        :both ->
          game_state = put_in(game_state.player1.board, full_island_set())
          put_in(game_state.player2.board, full_island_set())
      end
    end)

    :ok
  end

  defp full_island_set() do
    board = %{} = Board.new()

    {:ok, dot_coordinate} = Coordinate.new(10, 10)
    {:ok, dot} = Island.new(:dot, dot_coordinate)

    {:ok, atoll_coordinate} = Coordinate.new(1, 1)
    {:ok, atoll} = Island.new(:atoll, atoll_coordinate)

    {:ok, l_shape_coordinate} = Coordinate.new(4, 1)
    {:ok, l_shape} = Island.new(:l_shape, l_shape_coordinate)

    {:ok, s_shape_coordinate} = Coordinate.new(1, 5)
    {:ok, s_shape} = Island.new(:l_shape, s_shape_coordinate)

    {:ok, square_coordinate} = Coordinate.new(1, 8)
    {:ok, square} = Island.new(:square, square_coordinate)

    board
    |> Board.position_island(:atoll, atoll)
    |> Board.position_island(:dot, dot)
    |> Board.position_island(:l_shape, l_shape)
    |> Board.position_island(:s_shape, s_shape)
    |> Board.position_island(:square, square)
  end

  defp forest_island(board, island) do
    case island do
      :atoll ->
        Map.put(board, :atoll, %{board.atoll | hit_coordinates: board.atoll.coordinates})

      :dot ->
        Map.put(board, :dot, %{board.dot | hit_coordinates: board.dot.coordinates})

      :l_shape ->
        Map.put(board, :l_shape, %{board.l_shape | hit_coordinates: board.l_shape.coordinates})

      :s_shape ->
        Map.put(board, :s_shape, %{board.s_shape | hit_coordinates: board.s_shape.coordinates})

      :square ->
        Map.put(board, :square, %{board.square | hit_coordinates: board.square.coordinates})
    end
  end
end
