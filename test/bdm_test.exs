defmodule BDMTest do
  use ExUnit.Case

  test "works correctly for lists" do
    bdm = BDM.new(1, 2, 2)
    m = [0, 1, 0, 1, 0, 1]

    assert BDM.compute(bdm, m) == 4.912401704492526
  end

  test "works correctly for 2D matrices" do
    bdm = BDM.new(2, 2, 2, :ignore)

    m = [
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0]
    ]

    assert BDM.compute(bdm, m) == 10.072217827217502
  end

  test "works correctly for Nx.Tensor" do
    bdm = BDM.new(2, 2, 2, :ignore)

    m =
      Nx.tensor([
        [0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0],
        [0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0],
        [0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0]
      ])

    assert BDM.compute(bdm, m) == 10.072217827217502
  end
end
