defmodule BDM.LZC2D do
  @moduledoc """
  Compute Lempel–Ziv 1976 complexity for sequences and flattened matrices.
  """

  @doc """
  Compute LZ76 phrase complexity for an Nx tensor or a list/sequence.

  ## Parameters
    - tensor: a 2D Nx tensor or a lists of lists, typically binary (0/1).
      Matrices are flattened in row-major order. Each list element is treated as
      one symbol, including non-binary values.

  ## Returns
    - The number of phrases in the LZ76 exhaustive history parsing (zero for empty input)
  """
  @spec lzc(Nx.Tensor.t()) :: non_neg_integer()
  def lzc(%Nx.Tensor{} = tensor) do
    tensor
    |> Nx.to_flat_list()
    |> lzc()
  end

  @spec lzc(list() | binary()) :: non_neg_integer()
  def lzc(sequence) when is_binary(sequence) do
    sequence
    |> String.graphemes()
    |> lempel_ziv_complexity()
  end

  def lzc(sequence) when is_list(sequence) do
    sequence
    |> List.flatten()
    |> lempel_ziv_complexity()
  end

  defp lempel_ziv_complexity([]), do: 0
  defp lempel_ziv_complexity([_symbol]), do: 1
  defp lempel_ziv_complexity(sequence), do: do_lzc(sequence, length(sequence), 0, 1, 1, 1, 1)

  defp do_lzc(_sequence, n, _i, l, k, _k_max, c) when l + k > n, do: c + 1

  defp do_lzc(sequence, n, i, l, k, k_max, c) do
    if Enum.at(sequence, i + k - 1) == Enum.at(sequence, l + k - 1) do
      do_lzc(sequence, n, i, l, k + 1, k_max, c)
    else
      k_max = max(k, k_max)
      i = i + 1

      if i == l do
        next_l = l + k_max

        if next_l + 1 > n do
          c + 1
        else
          do_lzc(sequence, n, 0, next_l, 1, 1, c + 1)
        end
      else
        do_lzc(sequence, n, i, l, 1, k_max, c)
      end
    end
  end
end
