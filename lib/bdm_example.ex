defmodule BDMExample do
  @moduledoc """
  Example usage of the BDM module.
  """

  #
  # Computes block entropy for comparison with BDM.
  #
  defp block_entropy(data, block_size, boundary) do
    blocks =
      case data do
        data when is_list(data) and is_list(hd(data)) ->
          BDM.partition_2d(data, block_size, boundary)

        data when is_list(data) ->
          BDM.partition_1d(data, block_size, boundary)
      end

    # Calculate entropy over block distribution
    block_counts = Enum.frequencies(blocks)
    total_blocks = length(blocks)

    block_counts
    |> Enum.map(fn {_block, count} ->
      probability = count / total_blocks
      -probability * :math.log2(probability)
    end)
    |> Enum.sum()
  end

  def run do
    # Example 1: 1D binary string
    IO.puts("=== 1D Binary String Example ===")
    bdm_1d = BDM.new(1, 2, 2)
    binary_string = [0, 1, 0, 1, 0, 1, 1, 0, 1, 0]

    complexity = BDM.compute(bdm_1d, binary_string)
    entropy = block_entropy(binary_string, 2, :ignore)

    IO.puts("Data: #{inspect(binary_string)}")
    IO.puts("BDM Complexity: #{complexity}")
    IO.puts("Block Entropy: #{entropy}")

    # Example 2: 2D binary matrix with different block sizes
    IO.puts("\n=== 2D Binary Matrix Example ===")

    binary_matrix = [
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0],
      [0, 1, 0, 1, 0, 1],
      [1, 0, 1, 0, 1, 0]
    ]

    IO.puts("Matrix:")
    Enum.each(binary_matrix, &IO.puts("  #{inspect(&1)}"))

    # Test different block sizes
    [2, 3, 4]
    |> Enum.each(fn block_size ->
      bdm_2d = BDM.new(2, 2, block_size)
      complexity_2d = BDM.compute(bdm_2d, binary_matrix)
      entropy_2d = block_entropy(binary_matrix, block_size, :ignore)
      IO.puts("Block size #{block_size}x#{block_size}:")
      IO.puts("  BDM Complexity: #{complexity_2d}")
      IO.puts("  Block Entropy: #{entropy_2d}")
    end)
  end
end
