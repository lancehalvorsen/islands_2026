defmodule IslandsEngine.BoardTest do
  use ExUnit.Case, async: true

  alias IslandsEngine.Board
  alias IslandsEngine.Coordinate
  alias IslandsEngine.Island

  setup do
    board = %{} = Board.new()
    {:ok, dot_coordinate} = Coordinate.new(10, 10)
    {:ok, dot_island} = Island.new(:dot, dot_coordinate)
    %{board: board, dot_coordinate: dot_coordinate, dot_island: dot_island}
  end

  describe "new/0" do
    test "it returns a map" do
      assert %{} == Board.new()
    end
  end

  describe "position_island/3" do
    test "with a valid island that doesn't overlap any others", %{
      board: board,
      dot_coordinate: dot_coordinate,
      dot_island: dot_island
    } do
      result_board = Board.position_island(board, :dot, dot_island)
      assert MapSet.member?(result_board.dot.coordinates, dot_coordinate)

      {:ok, square_coordinate} = Coordinate.new(1, 1)
      {:ok, square_island} = Island.new(:square, square_coordinate)
      result_board_2 = Board.position_island(result_board, :square, square_island)
      assert MapSet.member?(result_board_2.square.coordinates, square_coordinate)
    end

    test "with a valid island that does overlap another island", %{
      board: board,
      dot_coordinate: dot_coordinate,
      dot_island: dot_island
    } do
      result_board = Board.position_island(board, :dot, dot_island)
      assert MapSet.member?(result_board.dot.coordinates, dot_coordinate)

      {:ok, square_coordinate} = Coordinate.new(9, 9)
      {:ok, square_island} = Island.new(:square, square_coordinate)

      assert {:error, :overlapping_island} ==
               Board.position_island(result_board, :square, square_island)
    end

    test "when positioning a duplicate island", %{
      board: board,
      dot_coordinate: dot_coordinate,
      dot_island: dot_island
    } do
      result_board = Board.position_island(board, :dot, dot_island)
      assert MapSet.member?(result_board.dot.coordinates, dot_coordinate)

      {:ok, second_dot_coordinate} = Coordinate.new(5, 5)
      {:ok, second_dot_island} = Island.new(:dot, second_dot_coordinate)

      result_board = Board.position_island(board, :dot, second_dot_island)
      assert MapSet.member?(result_board.dot.coordinates, second_dot_coordinate)
    end

    test "with an invalid island key", %{board: board, dot_island: dot_island} do
      assert {:error, :invalid_island_key} == Board.position_island(board, :wrong_key, dot_island)
    end
  end

  describe "all_islands_positioned/1" do
    test "when not all islands are positioned", %{board: board, dot_island: dot_island} do
      result_board = Board.position_island(board, :dot, dot_island)
      refute Board.all_islands_positioned?(result_board)
    end

    test "when all islands are positioned" do
      board = full_island_set()

      assert Board.all_islands_positioned?(board)
    end
  end

  describe "guess/2" do
    test "when the guess is a hit but does not win the game", %{
      board: board,
      dot_island: dot_island
    } do
      {:ok, atoll_coordinate} = Coordinate.new(1, 1)
      {:ok, atoll} = Island.new(:atoll, atoll_coordinate)
      {:ok, guess_coordinate} = Coordinate.new(10, 10)

      result_board =
        board
        |> Board.position_island(:dot, dot_island)
        |> Board.position_island(:atoll, atoll)

      forested_dot_island = forest_island(dot_island)

      assert {:hit, :dot, :no_win, %{atoll: atoll, dot: forested_dot_island}} ==
               Board.guess(result_board, guess_coordinate)
    end

    test "when the guess is a miss", %{board: board, dot_island: dot_island} do
      {:ok, guess_coordinate} = Coordinate.new(5, 5)
      result_board = Board.position_island(board, :dot, dot_island)

      assert {:miss, :none, :no_win, %{dot: dot_island}} ==
               Board.guess(result_board, guess_coordinate)
    end

    test "when the guess forests an island but does not win the game", %{
      board: board,
      dot_island: dot_island
    } do
      {:ok, atoll_coordinate} = Coordinate.new(1, 1)
      {:ok, atoll} = Island.new(:atoll, atoll_coordinate)
      {:ok, guess_coordinate} = Coordinate.new(10, 10)

      result_board =
        board
        |> Board.position_island(:dot, dot_island)
        |> Board.position_island(:atoll, atoll)

      forested_dot_island = forest_island(dot_island)

      assert {:hit, :dot, :no_win, %{atoll: atoll, dot: forested_dot_island}} ==
               Board.guess(result_board, guess_coordinate)
    end

    test "when a guess wins the game", %{board: board, dot_island: dot_island} do
      result_board = Board.position_island(board, :dot, dot_island)
      {:ok, guess_coordinate} = Coordinate.new(10, 10)

      forested_dot_island = forest_island(dot_island)

      assert {:hit, :dot, :win, %{dot: forested_dot_island}} ==
               Board.guess(result_board, guess_coordinate)
    end
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

  defp forest_island(island) do
    %{island | hit_coordinates: island.coordinates}
  end
end
