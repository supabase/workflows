defmodule WorkflowsTest do
  use ExUnit.Case
  doctest Workflows

  test "greets the world" do
    assert Workflows.hello() == :world
  end
end
