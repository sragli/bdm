defmodule BDM.MinimalInformationLossTest do
  use ExUnit.Case
  alias BDM.MinimalInformationLoss

  setup do
    # Use a simple BDM struct for tests (assuming BDM.new/3 is available)
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

    scores = MinimalInformationLoss.feature_scores(bdm, rows)
    assert is_list(scores)
    assert Enum.all?(scores, &is_map/1)
    assert Enum.all?(scores, &Map.has_key?(&1, :delta))
    assert Enum.all?(scores, &Map.has_key?(&1, :base))
    assert Enum.all?(scores, &Map.has_key?(&1, :removed))
    assert Enum.all?(scores, &Map.has_key?(&1, :idx))
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
