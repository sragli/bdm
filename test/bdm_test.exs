defmodule BDMTest do
  use ExUnit.Case

  test "works correctly for 1D list" do
    bdm = BDM.new(1, 2, 2)
    m = [0, 1, 0, 1, 0, 1]

    assert BDM.compute(bdm, m) == 4.912401704492526
  end

  test "works correctly for 2D matrix" do
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
    bdm = BDM.new(2, 2, 2, :ignore, :lzc)
    assert BDM.compute(bdm, m) == 4.169925001442312
  end

  test "works correctly for 2D Nx tensor" do
    m =
      Nx.tensor([
        [0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0],
        [0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0],
        [0, 1, 0, 1, 0, 1],
        [1, 0, 1, 0, 1, 0]
      ])

    bdm = BDM.new(2, 2, 2, :ignore)
    assert BDM.compute(bdm, m) == 10.072217827217502

    bdm = BDM.new(2, 2, 2, :ignore, :lzc)
    assert BDM.compute(bdm, m) == 4.169925001442312
  end

  test "LZC2D works correctly for 2D Nx tensor" do
    assert Nx.tensor([[1,0,1,1], [0,1,0,0]]) |> BDM.LZC2D.lzc() == 3
  end

  test "LZC2D works correctly for 2D matrix" do
    assert [[1,0,1,1], [0,1,0,0]] |> BDM.LZC2D.lzc() == 3
  end
end
