defmodule IslandsEngine.Guesses do
  alias IslandsEngine.Coordinate
  alias IslandsEngine.Guesses

  @enforce_keys [:hits, :misses]
  defstruct [:hits, :misses]

  def new() do
    %Guesses{hits: MapSet.new(), misses: MapSet.new()}
  end

  def add(%Guesses{} = guesses, result, %Coordinate{} = coordinate)
      when result in [:hit, :miss] do
    case result do
      :hit ->
        update_in(guesses.hits, &MapSet.put(&1, coordinate))

      :miss ->
        update_in(guesses.misses, &MapSet.put(&1, coordinate))
    end
  end
end
