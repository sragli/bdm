defmodule BDMTest do
  use ExUnit.Case

  test "works correctly for lists" do
    bdm = BDM.new(1, 2, 2)
    m = [0, 1, 0, 1, 0, 1]

    assert BDM.compute(bdm, m) == 5.169962500721156
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

    assert BDM.compute(bdm, m) == 9.339925001442312
  end

  test "works correctly for Nx.Tensor" do
    bdm = BDM.new(2, 2, 2, :ignore)

    m = Nx.tensor([
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0]
    ])

    assert BDM.compute(bdm, m) == 9.339925001442312
  end

  test "produces normalized results" do
    bdm = BDM.new(1, 2, 1, :ignore, nil, true)
    m = [0, 1, 0, 1, 0, 1]

    assert BDM.Utils.normalize(BDM.compute(bdm, m), m) == 0.28738729581946004
  end
end
