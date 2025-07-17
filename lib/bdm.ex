defmodule BDM do
  @moduledoc """
  Block Decomposition Method (BDM) implementation for approximating algorithmic complexity.

  This module implements the BDM algorithm developed by Hector Zenil et al
  to approximate the algorithmic complexity of datasets by decomposing them into
  smaller blocks and using precomputed CTM (Coding Theorem Method) values.
  """

  defstruct [:ndim, :nsymbols, :ctm_data, :warn_missing]

  @type t :: %__MODULE__{
          ndim: 1 | 2,
          nsymbols: integer(),
          ctm_data: map(),
          warn_missing: boolean()
        }

  @type boundary_condition :: :ignore | :recursive | :correlated
  @type binary_matrix :: list(list(integer()))
  @type binary_string :: list(integer())

  # Default CTM values for small binary strings (simplified example)
  @default_ctm_1d %{
    [0] => 1.0,
    [1] => 1.0,
    [0, 0] => 2.0,
    [0, 1] => 3.585,
    [1, 0] => 3.585,
    [1, 1] => 2.0,
    [0, 0, 0] => 3.0,
    [0, 0, 1] => 4.585,
    [0, 1, 0] => 5.170,
    [0, 1, 1] => 4.585,
    [1, 0, 0] => 4.585,
    [1, 0, 1] => 5.170,
    [1, 1, 0] => 4.585,
    [1, 1, 1] => 3.0
  }

  # Default CTM values for small 2x2 binary matrices (simplified example)
  @default_ctm_2d %{
    [[0, 0], [0, 0]] => 2.0,
    [[0, 0], [0, 1]] => 4.585,
    [[0, 0], [1, 0]] => 4.585,
    [[0, 0], [1, 1]] => 4.585,
    [[0, 1], [0, 0]] => 4.585,
    [[0, 1], [0, 1]] => 3.0,
    [[0, 1], [1, 0]] => 6.170,
    [[0, 1], [1, 1]] => 4.585,
    [[1, 0], [0, 0]] => 4.585,
    [[1, 0], [0, 1]] => 6.170,
    [[1, 0], [1, 0]] => 3.0,
    [[1, 0], [1, 1]] => 4.585,
    [[1, 1], [0, 0]] => 4.585,
    [[1, 1], [0, 1]] => 4.585,
    [[1, 1], [1, 0]] => 4.585,
    [[1, 1], [1, 1]] => 2.0
  }

  # Default CTM values for 3x3 binary matrices (examples of common patterns)
  @default_ctm_3x3 %{
    # All zeros
    [[0, 0, 0], [0, 0, 0], [0, 0, 0]] => 3.0,
    # All ones
    [[1, 1, 1], [1, 1, 1], [1, 1, 1]] => 3.0,
    # Single center bit
    [[0, 0, 0], [0, 1, 0], [0, 0, 0]] => 5.807,
    # Diagonal patterns
    [[1, 0, 0], [0, 1, 0], [0, 0, 1]] => 6.585,
    [[0, 0, 1], [0, 1, 0], [1, 0, 0]] => 6.585,
    # Horizontal stripes
    [[1, 1, 1], [0, 0, 0], [1, 1, 1]] => 5.170,
    [[0, 0, 0], [1, 1, 1], [0, 0, 0]] => 5.170,
    # Vertical stripes
    [[1, 0, 1], [1, 0, 1], [1, 0, 1]] => 5.170,
    [[0, 1, 0], [0, 1, 0], [0, 1, 0]] => 5.170,
    # Checkerboard patterns
    [[1, 0, 1], [0, 1, 0], [1, 0, 1]] => 6.170,
    [[0, 1, 0], [1, 0, 1], [0, 1, 0]] => 6.170,
    # Corner patterns
    [[1, 1, 0], [1, 0, 0], [0, 0, 0]] => 6.585,
    [[0, 1, 1], [0, 0, 1], [0, 0, 0]] => 6.585,
    [[0, 0, 0], [1, 0, 0], [1, 1, 0]] => 6.585,
    [[0, 0, 0], [0, 0, 1], [0, 1, 1]] => 6.585,
    # Cross patterns
    [[0, 1, 0], [1, 1, 1], [0, 1, 0]] => 6.170,
    [[1, 0, 1], [0, 0, 0], [1, 0, 1]] => 6.170,
    # L-shapes
    [[1, 1, 1], [1, 0, 0], [1, 0, 0]] => 6.585,
    [[1, 0, 0], [1, 0, 0], [1, 1, 1]] => 6.585,
    [[0, 0, 1], [0, 0, 1], [1, 1, 1]] => 6.585,
    [[1, 1, 1], [0, 0, 1], [0, 0, 1]] => 6.585,
    # T-shapes
    [[1, 1, 1], [0, 1, 0], [0, 1, 0]] => 6.585,
    [[0, 1, 0], [0, 1, 0], [1, 1, 1]] => 6.585,
    [[1, 0, 0], [1, 1, 1], [1, 0, 0]] => 6.585,
    [[0, 0, 1], [1, 1, 1], [0, 0, 1]] => 6.585,
    # Edge patterns
    [[1, 1, 1], [0, 0, 0], [0, 0, 0]] => 5.807,
    [[0, 0, 0], [0, 0, 0], [1, 1, 1]] => 5.807,
    [[1, 0, 0], [1, 0, 0], [1, 0, 0]] => 5.807,
    [[0, 0, 1], [0, 0, 1], [0, 0, 1]] => 5.807,
    # Random-like patterns (higher complexity)
    [[1, 0, 1], [0, 1, 1], [1, 0, 0]] => 8.170,
    [[0, 1, 0], [1, 0, 1], [1, 1, 0]] => 8.170,
    [[1, 1, 0], [0, 1, 0], [1, 0, 1]] => 8.170,
    [[0, 0, 1], [1, 1, 0], [0, 1, 1]] => 8.170
  }

  # Default CTM values for 4x4 binary matrices (examples of common patterns)
  @default_ctm_4x4 %{
    # All zeros
    [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]] => 4.0,
    # All ones
    [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]] => 4.0,
    # Single center block
    [[0, 0, 0, 0], [0, 1, 1, 0], [0, 1, 1, 0], [0, 0, 0, 0]] => 6.585,
    # Diagonal patterns
    [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]] => 7.170,
    [[0, 0, 0, 1], [0, 0, 1, 0], [0, 1, 0, 0], [1, 0, 0, 0]] => 7.170,
    # Horizontal stripes
    [[1, 1, 1, 1], [0, 0, 0, 0], [1, 1, 1, 1], [0, 0, 0, 0]] => 5.585,
    [[0, 0, 0, 0], [1, 1, 1, 1], [0, 0, 0, 0], [1, 1, 1, 1]] => 5.585,
    # Vertical stripes
    [[1, 0, 1, 0], [1, 0, 1, 0], [1, 0, 1, 0], [1, 0, 1, 0]] => 5.585,
    [[0, 1, 0, 1], [0, 1, 0, 1], [0, 1, 0, 1], [0, 1, 0, 1]] => 5.585,
    # Checkerboard patterns
    [[1, 0, 1, 0], [0, 1, 0, 1], [1, 0, 1, 0], [0, 1, 0, 1]] => 6.585,
    [[0, 1, 0, 1], [1, 0, 1, 0], [0, 1, 0, 1], [1, 0, 1, 0]] => 6.585,
    # Corner blocks
    [[1, 1, 0, 0], [1, 1, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]] => 6.585,
    [[0, 0, 1, 1], [0, 0, 1, 1], [0, 0, 0, 0], [0, 0, 0, 0]] => 6.585,
    [[0, 0, 0, 0], [0, 0, 0, 0], [1, 1, 0, 0], [1, 1, 0, 0]] => 6.585,
    [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 1, 1], [0, 0, 1, 1]] => 6.585,
    # Cross patterns
    [[0, 0, 1, 0], [0, 0, 1, 0], [1, 1, 1, 1], [0, 0, 1, 0]] => 7.170,
    [[0, 1, 0, 0], [1, 1, 1, 1], [0, 1, 0, 0], [0, 1, 0, 0]] => 7.170,
    # Frame patterns
    [[1, 1, 1, 1], [1, 0, 0, 1], [1, 0, 0, 1], [1, 1, 1, 1]] => 7.170,
    # L-shapes
    [[1, 1, 1, 1], [1, 0, 0, 0], [1, 0, 0, 0], [1, 0, 0, 0]] => 7.170,
    [[0, 0, 0, 1], [0, 0, 0, 1], [0, 0, 0, 1], [1, 1, 1, 1]] => 7.170,
    [[1, 0, 0, 0], [1, 0, 0, 0], [1, 0, 0, 0], [1, 1, 1, 1]] => 7.170,
    [[1, 1, 1, 1], [0, 0, 0, 1], [0, 0, 0, 1], [0, 0, 0, 1]] => 7.170,
    # T-shapes
    [[1, 1, 1, 1], [0, 1, 1, 0], [0, 1, 1, 0], [0, 0, 0, 0]] => 7.170,
    [[0, 0, 0, 0], [0, 1, 1, 0], [0, 1, 1, 0], [1, 1, 1, 1]] => 7.170,
    # Plus patterns
    [[0, 1, 1, 0], [1, 1, 1, 1], [1, 1, 1, 1], [0, 1, 1, 0]] => 7.170,
    [[1, 0, 0, 1], [0, 1, 1, 0], [0, 1, 1, 0], [1, 0, 0, 1]] => 7.585,
    # Diamond patterns
    [[0, 0, 1, 0], [0, 1, 1, 1], [1, 1, 1, 0], [0, 1, 0, 0]] => 8.170,
    [[0, 1, 0, 0], [1, 1, 1, 0], [0, 1, 1, 1], [0, 0, 1, 0]] => 8.170,
    # Spiral patterns
    [[1, 1, 1, 1], [0, 0, 0, 1], [0, 1, 1, 1], [0, 0, 0, 0]] => 8.170,
    [[0, 0, 0, 0], [1, 1, 1, 0], [1, 0, 0, 0], [1, 1, 1, 1]] => 8.170,
    # Random-like patterns (higher complexity)
    [[1, 0, 1, 0], [0, 1, 0, 1], [1, 1, 0, 0], [0, 0, 1, 1]] => 9.170,
    [[0, 1, 0, 1], [1, 0, 1, 0], [0, 0, 1, 1], [1, 1, 0, 0]] => 9.170,
    [[1, 1, 0, 0], [0, 1, 0, 1], [1, 0, 1, 0], [0, 0, 1, 1]] => 9.170,
    [[0, 0, 1, 1], [1, 0, 1, 0], [0, 1, 0, 1], [1, 1, 0, 0]] => 9.170,
    # Very complex patterns
    [[1, 0, 1, 1], [0, 1, 0, 1], [1, 1, 0, 0], [0, 1, 1, 0]] => 10.170,
    [[0, 1, 0, 0], [1, 0, 1, 1], [0, 1, 1, 0], [1, 0, 0, 1]] => 10.170
  }

  @doc """
  Creates a new BDM instance.

  ## Parameters
  - `ndim`: Dimensionality (1 for strings, 2 for matrices)
  - `nsymbols`: Number of symbols (typically 2 for binary)
  - `ctm_data`: Optional custom CTM lookup table
  - `warn_missing`: Whether to warn about missing CTM values

  ## Examples
      iex> BDM.new(1, 2)
      %BDM{ndim: 1, nsymbols: 2, ctm_data: ..., warn_missing: true}
  """
  @spec new(integer(), integer(), map() | nil, boolean()) :: t()
  def new(ndim, nsymbols, ctm_data \\ nil, warn_missing \\ true) do
    default_ctm =
      case ndim do
        1 -> @default_ctm_1d
        2 -> Map.merge(@default_ctm_2d, Map.merge(@default_ctm_3x3, @default_ctm_4x4))
      end

    %__MODULE__{
      ndim: ndim,
      nsymbols: nsymbols,
      ctm_data: ctm_data || default_ctm,
      warn_missing: warn_missing
    }
  end

  @doc """
  Computes the BDM complexity of a dataset.

  ## Parameters
  - `bdm`: BDM instance
  - `data`: Input data (list for 1D, list of lists for 2D)
  - `block_size`: Size of blocks for decomposition
  - `boundary`: Boundary condition (:ignore, :recursive, :correlated)

  ## Examples
      iex> bdm = BDM.new(1, 2)
      iex> BDM.compute(bdm, [0, 1, 0, 1, 0, 1], 2, :ignore)
      10.755
  """
  @spec compute(t(), binary_string() | binary_matrix(), integer(), boundary_condition()) ::
          float()
  def compute(%__MODULE__{ndim: 1} = bdm, data, block_size, boundary) when is_list(data) do
    data
    |> partition_1d(block_size, boundary)
    |> lookup_and_aggregate(bdm)
  end

  def compute(%__MODULE__{ndim: 2} = bdm, data, block_size, boundary) when is_list(data) do
    data
    |> partition_2d(block_size, boundary)
    |> lookup_and_aggregate(bdm)
  end

  @doc """
  Performs perturbation analysis to identify complexity-driving elements.
  """
  @spec perturbation_analysis(binary_string() | binary_matrix(), integer(), boundary_condition()) ::
          list({integer(), float()})
  def perturbation_analysis(data, block_size, boundary) do
    bdm = new(if(is_list(hd(data)), do: 2, else: 1), 2)
    original_complexity = compute(bdm, data, block_size, boundary)

    # Test perturbations at each position
    case data do
      data when is_list(data) and is_list(hd(data)) ->
        # 2D case
        for {row, i} <- Enum.with_index(data),
            {_val, j} <- Enum.with_index(row) do
          perturbed_data = flip_bit_2d(data, i, j)
          new_complexity = compute(bdm, perturbed_data, block_size, boundary)
          {{i, j}, new_complexity - original_complexity}
        end

      data when is_list(data) ->
        # 1D case
        for {_val, i} <- Enum.with_index(data) do
          perturbed_data = flip_bit_1d(data, i)
          new_complexity = compute(bdm, perturbed_data, block_size, boundary)
          {i, new_complexity - original_complexity}
        end
    end
  end

  @doc """
  Normalizes BDM value between 0 and 1.
  """
  @spec normalize(float(), binary_string() | binary_matrix()) :: float()
  def normalize(bdm_value, data) do
    # Minimum complexity: all same symbol
    min_complexity = 1.0

    # Maximum complexity: estimate based on data size
    data_size =
      case data do
        data when is_list(data) and is_list(hd(data)) ->
          length(data) * length(hd(data))

        data when is_list(data) ->
          length(data)
      end

    max_complexity = data_size * :math.log2(data_size)

    (bdm_value - min_complexity) / (max_complexity - min_complexity)
  end

  #
  # Partitions 1D data into blocks according to boundary condition.
  #
  @spec partition_1d(binary_string(), integer(), boundary_condition()) :: list(binary_string())
  def partition_1d(data, block_size, :ignore) do
    data
    |> Enum.chunk_every(block_size, block_size, :discard)
  end

  def partition_1d(data, block_size, :recursive) do
    chunks = Enum.chunk_every(data, block_size, block_size, :discard)
    remainder = Enum.drop(data, length(chunks) * block_size)

    if length(remainder) > 0 and length(remainder) >= div(block_size, 2) do
      recursive_chunks = partition_1d(remainder, div(block_size, 2), :recursive)
      chunks ++ recursive_chunks
    else
      chunks
    end
  end

  def partition_1d(data, block_size, :correlated) do
    data_length = length(data)

    if data_length < block_size do
      [data]
    else
      0..(data_length - block_size)
      |> Enum.map(&Enum.slice(data, &1, block_size))
    end
  end

  #
  # Partitions 2D data into blocks according to boundary condition.
  #
  @spec partition_2d(binary_matrix(), integer(), boundary_condition()) :: list(binary_matrix())
  def partition_2d(data, block_size, :ignore) do
    rows = length(data)
    cols = if rows > 0, do: length(hd(data)), else: 0

    for i <- 0..(div(rows, block_size) - 1),
        j <- 0..(div(cols, block_size) - 1) do
      extract_block(data, i * block_size, j * block_size, block_size, block_size)
    end
  end

  def partition_2d(data, block_size, :recursive) do
    primary_blocks = partition_2d(data, block_size, :ignore)

    # Handle remainder areas recursively (simplified implementation)
    primary_blocks
  end

  def partition_2d(data, block_size, :correlated) do
    rows = length(data)
    cols = if rows > 0, do: length(hd(data)), else: 0

    for i <- 0..(rows - block_size),
        j <- 0..(cols - block_size) do
      extract_block(data, i, j, block_size, block_size)
    end
  end

  #
  # Extracts a block from 2D data.
  #
  @spec extract_block(binary_matrix(), integer(), integer(), integer(), integer()) ::
          binary_matrix()
  defp extract_block(data, start_row, start_col, height, width) do
    data
    |> Enum.slice(start_row, height)
    |> Enum.map(&Enum.slice(&1, start_col, width))
  end

  #
  # Looks up CTM values for blocks and aggregates them using BDM formula.
  #
  @spec lookup_and_aggregate(list(binary_string() | binary_matrix()), t()) :: float()
  defp lookup_and_aggregate(blocks, %__MODULE__{ctm_data: ctm_data, warn_missing: warn_missing}) do
    # Count occurrences of each unique block
    block_counts = Enum.frequencies(blocks)

    # Apply BDM formula: sum of CTM(block) + log2(count) for each unique block
    block_counts
    |> Enum.map(fn {block, count} ->
      ctm_value = get_ctm_value(block, ctm_data, warn_missing)
      ctm_value + :math.log2(count)
    end)
    |> Enum.sum()
  end

  #
  # Gets CTM value for a block, with fallback for missing values.
  #
  @spec get_ctm_value(binary_string() | binary_matrix(), map(), boolean()) :: float()
  defp get_ctm_value(block, ctm_data, warn_missing) do
    case Map.get(ctm_data, block) do
      nil ->
        if warn_missing do
          IO.warn("Missing CTM value for block: #{inspect(block)}")
        end

        # Fallback: use maximum CTM value + 1 bit
        max_ctm = ctm_data |> Map.values() |> Enum.max()
        max_ctm + 1.0

      value ->
        value
    end
  end

  #
  # Flips a bit in 1D data.
  #
  @spec flip_bit_1d(binary_string(), integer()) :: binary_string()
  defp flip_bit_1d(data, index) do
    List.update_at(data, index, fn bit -> 1 - bit end)
  end

  #
  # Flips a bit in 2D data.
  #
  @spec flip_bit_2d(binary_matrix(), integer(), integer()) :: binary_matrix()
  defp flip_bit_2d(data, row, col) do
    List.update_at(data, row, fn row_data ->
      List.update_at(row_data, col, fn bit -> 1 - bit end)
    end)
  end
end
