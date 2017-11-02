defmodule QuoineClientTest do
  use ExUnit.Case
  doctest QuoineClient

  test "greets the world" do
    assert QuoineClient.hello() == :world
  end
end
