defmodule BDMUtils do

  @doc """
  Normalizes BDM value between 0 and 1.
  """
  @spec normalize(float(), BDM.binary_string() | BDM.binary_matrix()) :: float()
  def normalize(bdm_value, data) do
    # Minimum complexity: all same symbol
    min_complexity = 1.0

    # Complexity estimate based on data size
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

end
