defmodule MyLab3.LinearTest do
  use ExUnit.Case, async: true

  alias MyLab3.Interpolation.Linear

  test "interpolates y = x" do
    assert Linear.interp({0.0, 0.0}, {2.0, 2.0}, 1.0) == 1.0
  end

  test "interpolates y = 2x + 1" do
    assert Linear.interp({0.0, 1.0}, {2.0, 5.0}, 1.5) == 4.0
  end
end
