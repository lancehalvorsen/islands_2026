defmodule IslandsEngine.GuessesTest do
  use ExUnit.Case, async: true

  alias IslandsEngine.Coordinate
  alias IslandsEngine.Guesses

  describe "new/0" do
    test "returns the correct struct" do
      assert %Guesses{hits: MapSet.new(), misses: MapSet.new()} == Guesses.new()
    end
  end

  describe "add/3" do
    setup do
      guesses = Guesses.new()
      {:ok, coordinate} = Coordinate.new(1, 1)
      %{guesses: guesses, coordinate: coordinate}
    end

    test "adds hit coordinates", %{guesses: guesses, coordinate: coordinate} do
      assert MapSet.size(guesses.hits) == 0
      assert MapSet.size(guesses.misses) == 0

      result = Guesses.add(guesses, :hit, coordinate)

      assert MapSet.size(result.hits) == 1
      assert MapSet.size(result.misses) == 0
    end

    test "adds missed coordinates", %{guesses: guesses, coordinate: coordinate} do
      assert MapSet.size(guesses.hits) == 0
      assert MapSet.size(guesses.misses) == 0

      result = Guesses.add(guesses, :miss, coordinate)

      assert MapSet.size(result.hits) == 0
      assert MapSet.size(result.misses) == 1
    end

    test "does something with invalid actions", %{guesses: guesses, coordinate: coordinate} do
      assert_raise FunctionClauseError, fn ->
        Guesses.add(guesses, :oopsies, coordinate)
      end
    end
  end
end
