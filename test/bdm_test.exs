defmodule BdmTest do
  use ExUnit.Case

  test "works correctly" do
    bdm = BDM.new(1, 2)
    assert BDM.compute(bdm, [0, 1, 0, 1, 0, 1], 2, :ignore) == 5.169962500721156
  end
end
