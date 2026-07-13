defmodule IslandsEngine.IslandTest do
  use ExUnit.Case, async: true

  alias IslandsEngine.Coordinate
  alias IslandsEngine.Island

  describe "new/2" do
    setup do
      {:ok, upper_left} = Coordinate.new(1, 1)
      %{upper_left: upper_left}
    end

    test "can create an atoll", %{upper_left: upper_left} do
      {:ok, island} = Island.new(:atoll, upper_left)
      coordinates = island.coordinates

      {:ok, upper_right} = Coordinate.new(1, 2)
      {:ok, middle_right} = Coordinate.new(2, 2)
      {:ok, lower_left} = Coordinate.new(3, 1)
      {:ok, lower_right} = Coordinate.new(3, 2)

      assert island.hit_coordinates == MapSet.new()
      assert MapSet.size(coordinates) == 5
      assert MapSet.member?(coordinates, upper_left)
      assert MapSet.member?(coordinates, upper_right)
      assert MapSet.member?(coordinates, middle_right)
      assert MapSet.member?(coordinates, lower_left)
      assert MapSet.member?(coordinates, lower_right)
    end

    test "can create a dot island", %{upper_left: upper_left} do
      assert {:ok, island} = Island.new(:dot, upper_left)
      assert island.hit_coordinates == MapSet.new()
      assert island.coordinates == MapSet.new([upper_left])
    end

    test "can create an l_shape island", %{upper_left: upper_left} do
      {:ok, island} = Island.new(:l_shape, upper_left)
      coordinates = island.coordinates

      {:ok, middle_left} = Coordinate.new(2, 1)
      {:ok, lower_left} = Coordinate.new(3, 1)
      {:ok, lower_right} = Coordinate.new(3, 2)

      assert island.hit_coordinates == MapSet.new()
      assert MapSet.size(coordinates) == 4
      assert MapSet.member?(coordinates, upper_left)
      assert MapSet.member?(coordinates, middle_left)
      assert MapSet.member?(coordinates, lower_left)
      assert MapSet.member?(coordinates, lower_right)
    end

    test "can create an s_shape island", %{upper_left: upper_left} do
      {:ok, island} = Island.new(:s_shape, upper_left)
      coordinates = island.coordinates

      {:ok, upper_middle} = Coordinate.new(1, 2)
      {:ok, upper_right} = Coordinate.new(1, 3)
      {:ok, lower_left} = Coordinate.new(2, 1)
      {:ok, lower_middle} = Coordinate.new(2, 2)

      assert island.hit_coordinates == MapSet.new()
      assert MapSet.size(coordinates) == 4
      refute MapSet.member?(coordinates, upper_left)
      assert MapSet.member?(coordinates, upper_middle)
      assert MapSet.member?(coordinates, upper_right)
      assert MapSet.member?(coordinates, lower_left)
      assert MapSet.member?(coordinates, lower_middle)
    end

    test "can create a square island", %{upper_left: upper_left} do
      {:ok, island} = Island.new(:square, upper_left)
      coordinates = island.coordinates

      {:ok, upper_right} = Coordinate.new(1, 2)
      {:ok, lower_left} = Coordinate.new(2, 1)
      {:ok, lower_right} = Coordinate.new(2, 2)

      assert island.hit_coordinates == MapSet.new()
      assert MapSet.size(coordinates) == 4
      assert MapSet.member?(coordinates, upper_left)
      assert MapSet.member?(coordinates, upper_right)
      assert MapSet.member?(coordinates, lower_left)
      assert MapSet.member?(coordinates, lower_right)
    end

    test "errors when given an unknown island type", %{upper_left: upper_left} do
      assert {:error, :invalid_island_type} == Island.new(:totally_wrong, upper_left)
    end
  end

  describe "overlaps/2" do
    test "when two islands have at least one common coordinate" do
      {:ok, dot_coordinate} = Coordinate.new(1, 2)
      {:ok, square_upper_left_coordinate} = Coordinate.new(1, 1)

      {:ok, dot} = Island.new(:dot, dot_coordinate)
      {:ok, square} = Island.new(:square, square_upper_left_coordinate)

      assert Island.overlaps?(dot, square)
    end

    test "when two islands don't share any coordinates" do
      {:ok, dot_coordinate} = Coordinate.new(7, 7)
      {:ok, square_upper_left_coordinate} = Coordinate.new(1, 1)

      {:ok, dot} = Island.new(:dot, dot_coordinate)
      {:ok, square} = Island.new(:square, square_upper_left_coordinate)

      refute Island.overlaps?(dot, square)
    end
  end

  describe "guess/2" do
    test "when the guessed coordinate matches a coordinate of an island" do
      {:ok, dot_coordinate} = Coordinate.new(7, 7)
      {:ok, dot} = Island.new(:dot, dot_coordinate)

      {:hit, island} = Island.guess(dot, dot_coordinate)
      assert MapSet.size(island.hit_coordinates) == 1
      assert MapSet.member?(island.hit_coordinates, dot_coordinate)
    end

    test "when the guessed coordinate does not match a coordinate of an island" do
      {:ok, dot_coordinate} = Coordinate.new(7, 7)
      {:ok, dot} = Island.new(:dot, dot_coordinate)

      {:ok, other_coordinate} = Coordinate.new(1, 1)

      assert :miss == Island.guess(dot, other_coordinate)
    end
  end

  describe "forested/1" do
    test "when all the coordinates are hit" do
      {:ok, dot_coordinate} = Coordinate.new(7, 7)
      {:ok, dot} = Island.new(:dot, dot_coordinate)

      {:hit, response_island} = Island.guess(dot, dot_coordinate)
      assert Island.forested?(response_island)
    end

    test "when not all coordinates are hit" do
      {:ok, dot_coordinate} = Coordinate.new(7, 7)
      {:ok, dot} = Island.new(:dot, dot_coordinate)

      refute Island.forested?(dot)
    end
  end

  describe "types/0" do
    test "returns the correct list" do
      types = Island.types()
      assert length(types) == 5
      assert MapSet.new(types) == MapSet.new([:atoll, :dot, :l_shape, :s_shape, :square])
    end
  end
end
