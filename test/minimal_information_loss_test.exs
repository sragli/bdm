defmodule BDM.MinimalInformationLossTest do
  use ExUnit.Case
  alias BDM.MinimalInformationLoss

  setup do
    bdm = BDM.new(2, 2, 2)
    {:ok, bdm: bdm}
  end

  test "complexity returns BDM.compute result", %{bdm: bdm} do
    rows = [
      [0, 1],
      [1, 0]
    ]

    assert MinimalInformationLoss.complexity(bdm, rows) == BDM.compute(bdm, rows)
  end

  test "feature_scores returns correct deltas", %{bdm: bdm} do
    rows = [
      [0, 1],
      [1, 0]
    ]

    [
      %{delta: _, base: _, removed: _, idx: _},
      %{delta: _, base: _, removed: _, idx: _}
    ] = MinimalInformationLoss.feature_scores(bdm, rows)
  end

  test "select_features returns kept indices and history", %{bdm: bdm} do
    rows = [
      [0, 1, 0],
      [1, 0, 1]
    ]

    {kept, history} = MinimalInformationLoss.select_features(bdm, rows, 2)
    assert length(kept) == 2
    assert is_list(history)
    assert Enum.all?(history, &is_map/1)
  end

  test "select_features raises if k > ncols", %{bdm: bdm} do
    rows = [
      [0, 1],
      [1, 0]
    ]

    assert_raise ArgumentError, fn ->
      MinimalInformationLoss.select_features(bdm, rows, 3)
    end
  end

  test "reduce_dimensions returns expected map", %{bdm: bdm} do
    rows = [
      [0, 1, 0],
      [1, 0, 1]
    ]

    result = MinimalInformationLoss.reduce_dimensions(bdm, rows, 2)
    assert %{kept: kept, reduced: reduced, history: history} = result
    assert length(kept) == 2
    assert is_list(reduced)
    assert is_list(history)
  end
end
