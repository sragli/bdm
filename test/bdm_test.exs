defmodule BdmTest do
  use ExUnit.Case

  test "works correctly for 2x2 matrices" do
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
  end

  test "works correctly for 3x3 matrices" do
    bdm = BDM.new(2, 2)
    m = [
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0]
    ]
    assert BDM.compute(bdm, m, 3, :ignore) == 14.34
  end

  test "works correctly for 4x4 matrices" do
    bdm = BDM.new(2, 2)
    m = [
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0]
    ]
    assert BDM.compute(bdm, m, 4, :ignore) == 6.585
  end
end
