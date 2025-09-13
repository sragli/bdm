defmodule BDM.LZC2D do
  @moduledoc """
  Compute Lempel–Ziv Complexity (LZC) for 2D matrices.
  """

  @doc """
  Compute LZC for a binary Nx tensor or a list of lists (2D matrix).

  ## Parameters
    - tensor: a 2D Nx tensor or a lists of lists, typically binary (0/1).
      Non-binary values will be stringified.

  ## Returns
    - LZC value (positive integer, the count of distinct substrings encountered)
  """
  @spec lzc(Nx.Tensor.t()) :: pos_integer()
  def lzc(%Nx.Tensor{} = tensor) do
    tensor
    |> Nx.to_flat_list()
    |> lzc()
  end

  @spec lzc(list()) :: pos_integer()
  def lzc(tensor) do
    tensor
    |> Enum.map(&to_string/1)
    |> Enum.join()
    |> lempel_ziv_complexity()
  end

  # Core LZ complexity algorithm for strings
  defp lempel_ziv_complexity(sequence) when is_binary(sequence) do
    n = String.length(sequence)
    do_lzc(sequence, n, 0, 1, 1, 1)
  end

  # Recursive implementation of Kaspar & Schuster (1987) algorithm
  defp do_lzc(_s, n, i, k, l, c) when i + k > n or i + l > n, do: c

  defp do_lzc(s, n, i, k, l, c) do
    sub1 = String.slice(s, i, k)
    sub2 = String.slice(s, l, k)

    if sub1 == sub2 do
      do_lzc(s, n, i, k + 1, l, c)
    else
      if k > l do
        do_lzc(s, n, i + k, 1, 1, c + 1)
      else
        do_lzc(s, n, i, 1, l + 1, c)
      end
    end
  end
end
