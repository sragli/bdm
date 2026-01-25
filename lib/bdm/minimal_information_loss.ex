defmodule BDM.MinimalInformationLoss do
  @moduledoc """
  Feature selection and dimension reduction methods based on minimizing loss of
  algorithmic information, such that the estimated Kolmogorov complexity of the
  reduced object remains as close as possible to that of the original.
  The goal is to preserve causal/structural information, not just statistical
  regularities.
  """

  @doc """
  Computes baseline complexity of a binary matrix.

  By default we use a 2D BDM configured for binary matrices.
  """
  @spec complexity(BDM.t(), BDM.binary_matrix()) :: float()
  def complexity(bdm, rows) do
    BDM.compute(bdm, rows)
  end

  @doc """
  Scores each feature based on the change in the object’s estimated algorithmic
  information content after the removal of the feature.

  Returns a list of maps:

      [%{idx: 0, delta: 1.23, base: 10.0, removed: 8.77}, ...]

  `delta = base - removed` (non-negative in most cases).
  """
  @spec feature_scores(BDM.t(), BDM.binary_matrix()) :: list(map())
  def feature_scores(bdm, rows) do
    base = complexity(bdm, rows)
    n = ncols(rows)

    for j <- 0..(n - 1) do
      reduced = drop_col(rows, j)
      c = complexity(bdm, reduced)
      %{idx: j, delta: base - c, base: base, removed: c}
    end
    |> Enum.sort_by(& &1.delta, :desc)
  end

  @doc """
  Greedy feature selection. Iteratively removing the feature with the
  **smallest** delta until `k` remain.

  Returns `{kept_indices, history}` where history logs each removal.
  """
  @spec select_features(BDM.t(), BDM.binary_matrix(), pos_integer()) ::
          {list(integer()), list(map())}
  def select_features(bdm, rows, k) when is_integer(k) and k > 0 do
    n = ncols(rows)

    if k > n do
      raise ArgumentError, "k (#{k}) must be <= number of columns (#{n})"
    end

    kept = MapSet.new(0..(n - 1))
    history = []

    do_select(bdm, rows, k, kept, history)
  end

  defp do_select(bdm, rows, k, kept, history) do
    kept_list = kept |> Enum.sort()

    if length(kept_list) == k do
      {kept_list, Enum.reverse(history)}
    else
      sub = keep_cols(rows, kept_list)
      scores = feature_scores(bdm, sub)

      # scores are for the *submatrix* column indices; map them back to original indices
      # removing the smallest-delta column to minimize information loss
      worst = scores |> Enum.min_by(& &1.delta)
      remove_orig_idx = Enum.at(kept_list, worst.idx)

      new_kept = MapSet.delete(kept, remove_orig_idx)

      step = %{
        removed: remove_orig_idx,
        delta: worst.delta,
        base: worst.base,
        after: worst.removed,
        remaining: new_kept |> Enum.sort()
      }

      do_select(bdm, rows, k, new_kept, [step | history])
    end
  end

  @doc """
  Reduces a matrix to `k` features using greedy selection.

  Returns `%{kept: [...], reduced: rows_k, history: [...]}`.
  """
  @spec reduce_dimensions(BDM.t(), BDM.binary_matrix(), pos_integer()) :: %{
          history: [map()],
          kept: [integer()],
          reduced: list()
        }
  def reduce_dimensions(bdm, rows, k) do
    {kept, history} = select_features(bdm, rows, k)
    %{kept: kept, reduced: keep_cols(rows, kept), history: history}
  end

  # Drops a single column index (0-based).
  defp drop_col(rows, j) do
    Enum.map(rows, fn row -> List.delete_at(row, j) end)
  end

  # Keeps a list of column indices (0-based), in that order.
  defp keep_cols(rows, js) do
    Enum.map(rows, fn row -> Enum.map(js, &Enum.at(row, &1)) end)
  end

  # Returns number of columns.
  defp ncols(rows), do: rows |> hd() |> length()
end
