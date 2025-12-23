defmodule MyLab3.NewtonTest do
  use ExUnit.Case, async: true

  alias MyLab3.Interpolation.Newton

  test "builds coefficients for quadratic y = x^2" do
    points = [{0.0, 0.0}, {1.0, 1.0}, {2.0, 4.0}]
    coeffs = Newton.coefficients(points)
    xs = Enum.map(points, &elem(&1, 0))

    assert_in_delta(Newton.eval(coeffs, xs, 1.5), 2.25, 1.0e-9)
    assert_in_delta(Newton.eval(coeffs, xs, 0.5), 0.25, 1.0e-9)
  end

  test "handles cubic" do
    points = [{-1.0, -1.0}, {0.0, 0.0}, {1.0, 1.0}, {2.0, 8.0}]
    coeffs = Newton.coefficients(points)
    xs = Enum.map(points, &elem(&1, 0))

    assert_in_delta(Newton.eval(coeffs, xs, 1.5), 3.375, 1.0e-6)
  end
end
