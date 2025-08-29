defmodule BDM do
  @moduledoc """
  Block Decomposition Method (BDM) implementation for approximating algorithmic complexity.
  """

  defstruct [:ndim, :nsymbols, :block_size, :boundary, :ctm_data, :warn_missing]

  @type t :: %__MODULE__{
          ndim: 1 | 2,
          nsymbols: integer(),
          block_size: integer(),
          boundary: boundary_condition(),
          ctm_data: map(),
          warn_missing: boolean()
        }

  @type boundary_condition :: :ignore | :correlated
  @type binary_matrix :: list(list(integer())) | Nx.Tensor.t()
  @type binary_string :: list(integer())

  @doc """
  Creates a new BDM instance.

  ## Parameters
  - `ndim`: Dimensionality (1 for strings, 2 for matrices)
  - `nsymbols`: Number of symbols (typically 2 for binary)
  - `block_size`: Size of blocks for decomposition
  - `boundary`: Boundary condition (:ignore, :correlated)
  - `ctm_data`: Optional custom CTM lookup table
  - `warn_missing`: Whether to warn about missing CTM values

  ## Examples
      iex> BDM.new(1, 2, 2)
      %BDM{ndim: 1, nsymbols: 2, block_size: 2, ctm_data: ..., warn_missing: true}
  """
  @spec new(integer(), integer(), integer(), boundary_condition(), map() | nil, boolean()) :: t()
  def new(ndim, nsymbols, block_size, boundary \\ :ignore, ctm_data \\ nil, warn_missing \\ true) do
    %__MODULE__{
      ndim: ndim,
      nsymbols: nsymbols,
      block_size: block_size,
      boundary: boundary,
      ctm_data: ctm_data || load_ctm_data(ndim, block_size),
      warn_missing: warn_missing
    }
  end

  @doc """
  Computes the BDM complexity of a dataset.

  ## Parameters
  - `bdm`: BDM instance
  - `data`: Input data (list for 1D, Nx.Tensor or list of lists for 2D)
  """
  @spec compute(t(), binary_string() | binary_matrix()) :: float()
  def compute(%__MODULE__{ndim: 1, block_size: block_size, boundary: boundary} = bdm, data)
      when is_list(data) do
    data
    |> partition_1d(block_size, boundary)
    |> lookup_and_aggregate(bdm)
  end

  def compute(
        %__MODULE__{ndim: 2, block_size: block_size, boundary: boundary} = bdm,
        %Nx.Tensor{} = data
      ) do
    data
    |> partition_2d(block_size, boundary)
    |> lookup_and_aggregate(bdm)
  end

  def compute(%__MODULE__{ndim: 2, block_size: block_size, boundary: boundary} = bdm, data)
      when is_list(data) do
    data
    |> partition_2d(block_size, boundary)
    |> lookup_and_aggregate(bdm)
  end

  @doc """
  Partitions 1D data into blocks according to boundary condition.
  """
  @spec partition_1d(binary_string(), integer(), boundary_condition()) :: list(binary_string())

  def partition_1d(data, block_size, :ignore) do
    data
    |> Enum.chunk_every(block_size, block_size, :discard)
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

  @doc """
  Partitions 2D data into blocks according to boundary condition.
  """
  @spec partition_2d(binary_matrix(), integer(), boundary_condition()) :: list(binary_matrix())

  def partition_2d(%Nx.Tensor{} = data, block_size, :ignore) do
    {rows, cols} = Nx.shape(data)

    for i <- 0..(div(rows, block_size) - 1),
        j <- 0..(div(cols, block_size) - 1) do
      extract_block(data, i * block_size, j * block_size, block_size, block_size)
      |> Nx.to_list()
    end
  end

  def partition_2d(data, block_size, :ignore) do
    rows = length(data)
    cols = if rows > 0, do: length(hd(data)), else: 0

    for i <- 0..(div(rows, block_size) - 1),
        j <- 0..(div(cols, block_size) - 1) do
      extract_block(data, i * block_size, j * block_size, block_size, block_size)
    end
  end

  def partition_2d(%Nx.Tensor{} = data, block_size, :correlated) do
    {rows, cols} = Nx.shape(data)

    for i <- 0..(rows - block_size),
        j <- 0..(cols - block_size) do
      extract_block(data, i, j, block_size, block_size)
      |> Nx.to_list()
    end
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

  defp extract_block(%Nx.Tensor{} = tensor, start_row, start_col, height, width) do
    tensor
    |> Nx.slice([start_row, start_col], [height, width])
  end

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

  @spec load_ctm_data(integer(), integer()) :: map()
  defp load_ctm_data(1, block_size) do
    Path.join(:code.priv_dir(:bdm), "ctm-b2-d12.etf")
    |> File.read!()
    |> :erlang.binary_to_term()
    |> Stream.filter(fn {list, _k} -> block_size == length(list) end)
    |> Stream.flat_map(fn {list, k} -> [{list, k}, {Enum.map(list, fn x -> 1 - x end), k}] end)
    |> Enum.into(%{})
  end

  defp load_ctm_data(2, block_size) do
    Path.join(:code.priv_dir(:bdm), "ctm-b2-d4x4.etf")
    |> File.read!()
    |> :erlang.binary_to_term()
    |> Stream.filter(fn {list, _k} -> block_size == trunc(:math.sqrt(length(list))) end)
    |> Stream.flat_map(fn {list, k} -> [
        {Enum.chunk_every(list, block_size), k},
        {Enum.chunk_every(Enum.map(list, fn x -> 1 - x end), block_size), k}
      ] end)
    |> Enum.into(%{})
  end
end
