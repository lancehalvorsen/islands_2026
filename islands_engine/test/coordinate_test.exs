defmodule IslandsEngine.CoordinateTest do
  use ExUnit.Case, async: true

  alias IslandsEngine.Coordinate

  describe "new/2" do
    test "with valid coordinates" do
      assert {:ok, %Coordinate{row: 1, col: 10}} == Coordinate.new(1, 10)
      assert {:ok, %Coordinate{row: 10, col: 1}} == Coordinate.new(10, 1)
    end

    test "with invalid coordinates" do
      # Out of range above
      assert {:error, :invalid_coordinate} == Coordinate.new(1, 11)
      assert {:error, :invalid_coordinate} == Coordinate.new(11, 1)

      # Out of range below
      assert {:error, :invalid_coordinate} == Coordinate.new(0, 1)
      assert {:error, :invalid_coordinate} == Coordinate.new(1, 0)

      # Negative numbers
      assert {:error, :invalid_coordinate} == Coordinate.new(1, -10)
      assert {:error, :invalid_coordinate} == Coordinate.new(-1, 10)
    end
  end
end
