defmodule DistopyTest do
  use ExUnit.Case
  doctest Distopy

  test "greets the world" do
    assert Distopy.hello() == :world
  end
end
