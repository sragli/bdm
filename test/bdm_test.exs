defmodule BDMTest do
  use ExUnit.Case

  test "works correctly for lists" do
    bdm = BDM.new(1, 2)
    m = [0, 1, 0, 1, 0, 1]

    assert BDM.compute(bdm, m, 1, :ignore) == 5.169925001442312
    assert BDM.compute(bdm, m, 2, :ignore) == 5.169962500721156
    assert BDM.compute(bdm, m, 3, :ignore) == 10.34
  end

  test "works correctly for 2d matrices" do
    bdm = BDM.new(2, 2)

    m = [
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0]
    ]

    assert BDM.compute(bdm, m, 2, :ignore) == 9.339925001442312
    assert BDM.compute(bdm, m, 3, :ignore) == 14.34
    assert BDM.compute(bdm, m, 4, :ignore) == 6.585
  end
end
