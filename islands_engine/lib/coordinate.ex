defmodule IslandsEngine.Coordinate do
  alias IslandsEngine.Coordinate

  @enforce_keys [:row, :col]
  defstruct [:row, :col]

  def new(row, col) when row in 1..10 and col in 1..10 do
    {:ok, %Coordinate{row: row, col: col}}
  end

  def new(_row, _col) do
    {:error, :invalid_coordinate}
  end
end
