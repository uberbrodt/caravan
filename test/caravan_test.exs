defmodule CaravanTest do
  use ExUnit.Case
  doctest Caravan

  test "greets the world" do
    assert Caravan.hello() == :world
  end
end
