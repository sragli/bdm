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
    assert BDM.compute(bdm, m) == 6.169925001442312
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
    assert BDM.compute(bdm, m) == 6.169925001442312
  end

  test "LZC2D works correctly for 2D Nx tensor" do
    assert Nx.tensor([[1, 0, 1, 1], [0, 1, 0, 0]]) |> BDM.LZC2D.lzc() == 5
  end

  test "LZC2D works correctly for 2D matrix" do
    assert [[1, 0, 1, 1], [0, 1, 0, 0]] |> BDM.LZC2D.lzc() == 5
  end

  test "partition_1d ignore discards remainder" do
    assert BDM.partition_1d([1, 0, 1], 2, :ignore) == [[1, 0]]
  end

  test "partition_1d correlated returns full data when shorter than block" do
    assert BDM.partition_1d([0, 1], 3, :correlated) == [[0, 1]]
  end

  test "partition_2d ignore discards leftover rows and cols (list input)" do
    m = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9]
    ]

    assert BDM.partition_2d(m, 2, :ignore) == [[[1, 2], [4, 5]]]
  end

  test "partition_2d correlated returns sliding 2x2 blocks (list input)" do
    m = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9]
    ]

    expected = [
      [[1, 2], [4, 5]],
      [[2, 3], [5, 6]],
      [[4, 5], [7, 8]],
      [[5, 6], [8, 9]]
    ]

    assert BDM.partition_2d(m, 2, :correlated) == expected
  end

  test "partition_2d returns no blocks when input is smaller than the block" do
    assert BDM.partition_2d([[0]], 2, :ignore) == []
    assert BDM.partition_2d([[0]], 2, :correlated) == []
    assert BDM.partition_2d(Nx.tensor([[0]]), 2, :ignore) == []
    assert BDM.partition_2d(Nx.tensor([[0]]), 2, :correlated) == []
  end

  test "partition_2d rejects ragged matrices and non-2D tensors" do
    assert_raise ArgumentError, fn ->
      BDM.partition_2d([[0, 1], [1]], 2, :ignore)
    end

    assert_raise ArgumentError, fn ->
      BDM.partition_2d(Nx.tensor([0, 1]), 1, :ignore)
    end
  end

  test "ctm fallback with missing block and warn" do
    bdm = BDM.new(1, 2, 2, :ignore, :ctm, %{[0, 0] => 2.0}, true)
    data = [1, 1, 1, 1]

    stderr =
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        assert BDM.compute(bdm, data) == 4.0
      end)

    assert stderr =~ "Missing CTM value for block"
  end

  test "ctm fallback without warn flag does not print" do
    bdm = BDM.new(1, 2, 2, :ignore, :ctm, %{[0, 0] => 2.0}, false)
    data = [1, 1, 1, 1]

    stderr =
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        assert BDM.compute(bdm, data) == 4.0
      end)

    assert stderr == ""
  end

  test "lzc handles empty and repeated sequences" do
    assert BDM.LZC2D.lzc([]) == 0
    assert BDM.LZC2D.lzc([0]) == 1
    assert BDM.LZC2D.lzc([0, 1]) == 2
    assert BDM.LZC2D.lzc([0, 1, 0, 1]) == 3
    assert BDM.LZC2D.lzc([0, 0, 0, 0]) == 2
  end

  test "lzc handles non-binary values (flat list)" do
    assert BDM.LZC2D.lzc([2, 3]) == 2
  end

  test "compute with lzc backend for 1D list" do
    bdm = BDM.new(1, 2, 2, :ignore, :lzc)
    assert BDM.compute(bdm, [0, 1, 0, 1]) == 3.0
  end

  test "single_bit_perturbations for 1D and 2D" do
    bdm1 = BDM.new(1, 2, 2)
    data1 = [0, 1, 0]
    expected1 = [[1, 1, 0], [0, 0, 0], [0, 1, 1]]
    assert BDM.PerturbationAnalysis.single_bit_perturbations(bdm1, data1) == expected1

    bdm2 = BDM.new(2, 2, 2)
    data2 = [[0, 1], [1, 0]]

    expected2 = [
      [[1, 1], [1, 0]],
      [[0, 0], [1, 0]],
      [[0, 1], [0, 0]],
      [[0, 1], [1, 1]]
    ]

    assert BDM.PerturbationAnalysis.single_bit_perturbations(bdm2, data2) == expected2
  end

  test "2D random perturbations flip the requested number of distinct cells" do
    bdm = BDM.new(2, 2, 2)
    data = [[0, 0, 0], [0, 0, 0]]

    perturbations = BDM.PerturbationAnalysis.random_perturbations(bdm, data, 10, 0.5)

    assert length(perturbations) == 10

    assert Enum.all?(perturbations, fn matrix ->
             Enum.sum(Enum.map(matrix, &Enum.sum/1)) == 3
           end)

    tensor_perturbations =
      BDM.PerturbationAnalysis.random_perturbations(
        bdm,
        Nx.tensor(data),
        1,
        1.0
      )

    assert [flipped_tensor] = tensor_perturbations
    assert Nx.to_list(flipped_tensor) == [[1, 1, 1], [1, 1, 1]]
  end

  test "relative perturbation change is undefined for a zero baseline" do
    bdm = BDM.new(1, 2, 2, :ignore, :ctm, %{[0, 0] => 0.0, [1, 1] => 2.0}, false)

    {_base, [result]} =
      BDM.PerturbationAnalysis.calculate_perturbation_effects(bdm, [0, 0], [[1, 1]])

    assert result.delta_bdm == 2.0
    assert result.relative_change == nil
  end

  test "landscape marks bounded random samples" do
    bdm = BDM.new(1, 2, 2)
    data = Enum.map(0..10, &rem(&1, 2))

    [landscape] = BDM.PerturbationAnalysis.perturbation_landscape(bdm, data, 5)
    [first_effect | _] = landscape.effects

    assert first_effect.num_flips == 1
    assert first_effect.sampled
    assert first_effect.sample_count == 10
  end

  test "stability_coefficient returns expected structure and bounds" do
    bdm = BDM.new(1, 2, 2)
    data = [0, 1, 0, 1]

    res = BDM.PerturbationAnalysis.stability_coefficient(bdm, data, 5, 0.2)
    assert is_map(res)
    assert Map.has_key?(res, :stability_score)
    assert res.stability_score >= 0.0 and res.stability_score <= 1.0
  end

  test "detect_critical_positions filters and sorts" do
    profile = [
      %{position: 0, sensitivity: 0.5},
      %{position: 1, sensitivity: 2.0},
      %{position: 2, sensitivity: 1.5}
    ]

    out = BDM.PerturbationAnalysis.detect_critical_positions(profile, 1.0)
    assert Enum.map(out, & &1.position) == [1, 2]
  end
end
