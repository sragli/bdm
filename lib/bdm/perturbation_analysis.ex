defmodule BDM.PerturbationAnalysis do
  @moduledoc """
  Tools for analyzing how perturbations affect BDM complexity estimates in order to
  identify complexity-driving elements, sensitivity, critical points and stability.
  """

  @doc """
  Generates all possible single-bit flip perturbations of the data.
  """
  @spec single_bit_perturbations(BDM.t(), BDM.binary_string() | BDM.binary_matrix()) ::
          list(BDM.binary_string() | BDM.binary_matrix())
  def single_bit_perturbations(%BDM{ndim: 1}, data) do
    for i <- indices(length(data)) do
      flip_bit_1d(data, i)
    end
  end

  def single_bit_perturbations(%BDM{ndim: 2} = bdm, %Nx.Tensor{} = data) do
    single_bit_perturbations(bdm, Nx.to_list(data))
  end

  def single_bit_perturbations(%BDM{ndim: 2}, data) do
    validate_matrix!(data)

    for {row, i} <- Enum.with_index(data),
        {_val, j} <- Enum.with_index(row) do
      flip_bit_2d(data, i, j)
    end
  end

  @doc """
  Generates random perturbations with specified noise level.
  noise_level: fraction of bits to flip (0.0 to 1.0)
  """
  @spec random_perturbations(
          BDM.t(),
          BDM.binary_string() | BDM.binary_matrix(),
          pos_integer(),
          number()
        ) ::
          list(BDM.binary_string() | BDM.binary_matrix())
  def random_perturbations(%BDM{ndim: 1}, data, num_perturbations, noise_level) do
    validate_perturbation_options!(num_perturbations, noise_level)
    data_length = length(data)
    num_flips = round(data_length * noise_level)

    for _ <- 1..num_perturbations do
      positions = Enum.take_random(indices(data_length), num_flips)
      flip_positions_1d(data, positions)
    end
  end

  def random_perturbations(
        %BDM{ndim: 2} = bdm,
        %Nx.Tensor{} = data,
        num_perturbations,
        noise_level
      ) do
    random_perturbations(bdm, Nx.to_list(data), num_perturbations, noise_level)
    |> Enum.map(&Nx.tensor/1)
  end

  def random_perturbations(%BDM{ndim: 2}, data, num_perturbations, noise_level) do
    validate_perturbation_options!(num_perturbations, noise_level)
    validate_matrix!(data)
    data_length = length(data)
    data_width = if data_length > 0, do: length(hd(data)), else: 0
    num_cells = data_length * data_width
    num_flips = round(num_cells * noise_level)

    for _ <- 1..num_perturbations do
      positions =
        Enum.take_random(indices(num_cells), num_flips)
        |> Enum.map(&{div(&1, data_width), rem(&1, data_width)})

      flip_positions_2d(data, positions)
    end
  end

  @doc """
  Calculates BDM for original and all perturbed versions. `relative_change` is
  `nil` when the original BDM is zero, where a relative change is undefined.
  """
  @spec calculate_perturbation_effects(BDM.t(), BDM.binary_string() | BDM.binary_matrix(), list()) ::
          {float(), list(map())}
  def calculate_perturbation_effects(bdm, original_data, perturbations) do
    original_bdm = BDM.compute(bdm, original_data)

    perturbation_results =
      perturbations
      |> Enum.with_index()
      |> Enum.map(fn {perturbed_data, index} ->
        perturbed_bdm = BDM.compute(bdm, perturbed_data)
        delta_bdm = perturbed_bdm - original_bdm

        %{
          index: index,
          original_bdm: original_bdm,
          perturbed_bdm: perturbed_bdm,
          delta_bdm: delta_bdm,
          relative_change: if(original_bdm == 0.0, do: nil, else: delta_bdm / original_bdm)
        }
      end)

    {original_bdm, perturbation_results}
  end

  @doc """
  Creates a sensitivity profile showing which positions are most sensitive to perturbation.
  """
  @spec sensitivity_profile(BDM.t(), BDM.binary_string() | BDM.binary_matrix()) :: list(map())
  def sensitivity_profile(bdm, data) do
    single_perturbations = single_bit_perturbations(bdm, data)
    {_, results} = calculate_perturbation_effects(bdm, data, single_perturbations)

    results
    |> Enum.map(fn result ->
      %{
        position: result.index,
        sensitivity: abs(result.delta_bdm),
        relative_sensitivity:
          if(is_number(result.relative_change), do: abs(result.relative_change), else: nil)
      }
    end)
  end

  @doc """
  Identifies positions where perturbation sensitivity exceeds threshold.
  """
  @spec detect_critical_positions(list(map()), number()) :: list(map())
  def detect_critical_positions(sensitivity_profile, threshold \\ 1.0) do
    sensitivity_profile
    |> Enum.filter(fn point -> point.sensitivity > threshold end)
    |> Enum.sort_by(& &1.sensitivity, :desc)
  end

  @doc """
  Creates a landscape showing cumulative effects of multi-bit perturbations.

  For each flip count, the 1D form returns a maximum effect and the 2D form
  returns maximum, minimum, and average effects. When the number of combinations
  exceeds the evaluation limit, statistics are based on a bounded random sample
  and the result marks `sampled: true`.
  """
  @spec perturbation_landscape(BDM.t(), BDM.binary_string() | BDM.binary_matrix(), integer()) ::
          list(map())
  def perturbation_landscape(%BDM{ndim: 1} = bdm, data, radius) do
    validate_landscape_radius!(radius)
    original_bdm = BDM.compute(bdm, data)

    data_length = length(data)

    # Generate perturbations in a sliding window
    for center <- centers(data_length, radius) do
      positions = (center - radius)..(center + radius) |> Enum.to_list()

      # Try all combinations of flips in this window
      perturbation_effects =
        for num_flips <- flip_counts(length(positions)) do
          {combinations, sampled?} = choose_combinations(positions, num_flips, 10)

          effects =
            for combination <- combinations do
              perturbed_data = flip_positions_1d(data, combination)
              perturbed_bdm = BDM.compute(bdm, perturbed_data)
              perturbed_bdm - original_bdm
            end

          max_effect = if effects != [], do: Enum.max(effects), else: 0.0

          %{
            num_flips: num_flips,
            max_effect: max_effect,
            sample_count: length(effects),
            sampled: sampled?
          }
        end

      %{
        center: center,
        effects: perturbation_effects
      }
    end
  end

  def perturbation_landscape(%BDM{ndim: 2} = bdm, %Nx.Tensor{} = data, radius) do
    perturbation_landscape(bdm, Nx.to_list(data), radius)
  end

  def perturbation_landscape(%BDM{ndim: 2} = bdm, data, radius) do
    validate_landscape_radius!(radius)
    validate_matrix!(data)
    original_bdm = BDM.compute(bdm, data)

    data_height = length(data)
    data_width = if data_height > 0, do: length(hd(data)), else: 0

    # Generate perturbations in a sliding 2D window
    for center_row <- centers(data_height, radius),
        center_col <- centers(data_width, radius) do
      # Get all positions in the window around the center
      # Only processes positions that allow a full radius window
      positions =
        for row <- (center_row - radius)..(center_row + radius),
            col <- (center_col - radius)..(center_col + radius) do
          {row, col}
        end

      # Limits for performance
      max_flips = 8
      max_combinations = 20

      # Try all combinations of flips in this window
      # Only processes positions that allow a full radius window
      perturbation_effects =
        for num_flips <- flip_counts(length(positions), max_flips) do
          {combinations, sampled?} = choose_combinations(positions, num_flips, max_combinations)

          effects =
            for combination <- combinations do
              perturbed_data = flip_positions_2d(data, combination)
              perturbed_bdm = BDM.compute(bdm, perturbed_data)
              perturbed_bdm - original_bdm
            end

          effect_stats_2d(num_flips, effects, sampled?)
        end

      %{
        center_row: center_row,
        center_col: center_col,
        effects: perturbation_effects
      }
    end
  end

  @doc """
  Calculates perturbation-effect dispersion relative to the mean absolute effect.

  The coefficient is zero when all effects are zero; signed effects with a
  near-zero mean remain well-defined because normalization uses absolute effects.
  """
  @spec stability_coefficient(
          BDM.t(),
          BDM.binary_string() | BDM.binary_matrix(),
          pos_integer(),
          number()
        ) :: map()
  def stability_coefficient(bdm, data, num_trials \\ 50, noise_level \\ 0.1) do
    validate_perturbation_options!(num_trials, noise_level)
    original_bdm = BDM.compute(bdm, data)

    perturbations = random_perturbations(bdm, data, num_trials, noise_level)

    {_, results} = calculate_perturbation_effects(bdm, data, perturbations)

    delta_bdms = Enum.map(results, & &1.delta_bdm)
    mean_delta = Enum.sum(delta_bdms) / length(delta_bdms)

    variance =
      Enum.sum(Enum.map(delta_bdms, fn x -> (x - mean_delta) * (x - mean_delta) end)) /
        length(delta_bdms)

    std_dev = :math.sqrt(variance)

    mean_absolute_delta = Enum.sum(Enum.map(delta_bdms, &abs/1)) / length(delta_bdms)

    effect_dispersion =
      if mean_absolute_delta != 0, do: std_dev / mean_absolute_delta, else: 0.0

    %{
      original_bdm: original_bdm,
      mean_perturbation_effect: mean_delta,
      std_perturbation_effect: std_dev,
      coefficient_of_variation: effect_dispersion,
      # Higher is more stable
      stability_score: 1.0 / (1.0 + effect_dispersion)
    }
  end

  defp flip_positions_1d(data, positions) do
    Enum.reduce(positions, data, fn pos, acc ->
      List.update_at(acc, pos, fn bit -> 1 - bit end)
    end)
  end

  defp flip_positions_2d(data, positions) do
    Enum.reduce(positions, data, fn {row, col}, acc ->
      List.update_at(acc, row, fn row_list ->
        List.update_at(row_list, col, fn bit -> 1 - bit end)
      end)
    end)
  end

  @spec flip_bit_1d(BDM.binary_string(), integer()) :: BDM.binary_string()
  defp flip_bit_1d(data, index) do
    List.update_at(data, index, fn bit -> 1 - bit end)
  end

  @spec flip_bit_2d(BDM.binary_matrix(), integer(), integer()) :: BDM.binary_matrix()
  defp flip_bit_2d(data, row, col) do
    List.update_at(data, row, fn row_data ->
      List.update_at(row_data, col, fn bit -> 1 - bit end)
    end)
  end

  defp combinations([], 0), do: Stream.map([[]], & &1)
  defp combinations([], _n), do: Stream.map([], & &1)

  defp combinations([head | tail], n) do
    Stream.concat(
      Stream.map(combinations(tail, n - 1), &[head | &1]),
      combinations(tail, n)
    )
  end

  defp choose_combinations(positions, num_flips, limit) do
    count = binomial(length(positions), num_flips)

    if count <= limit do
      {Enum.to_list(combinations(positions, num_flips)), false}
    else
      sampled =
        Enum.reduce_while(1..(limit * 20), MapSet.new(), fn _, acc ->
          candidate = Enum.take_random(positions, num_flips) |> Enum.sort()
          next = MapSet.put(acc, candidate)

          if MapSet.size(next) == limit, do: {:halt, next}, else: {:cont, next}
        end)

      {MapSet.to_list(sampled), true}
    end
  end

  defp binomial(n, k) when k < 0 or k > n, do: 0
  defp binomial(_n, 0), do: 1
  defp binomial(n, n), do: 1

  defp binomial(n, k) do
    k = min(k, n - k)

    Enum.reduce(1..k, 1, fn index, acc ->
      div(acc * (n - k + index), index)
    end)
  end

  defp flip_counts(count, max_count \\ nil)
  defp flip_counts(count, _max_count) when count < 1, do: []
  defp flip_counts(count, nil), do: 1..count
  defp flip_counts(count, max_count), do: 1..min(count, max_count)

  defp indices(0), do: []
  defp indices(count), do: 0..(count - 1)

  defp centers(size, radius) when size >= 2 * radius + 1 do
    radius..(size - radius - 1)
  end

  defp centers(_size, _radius), do: []

  defp validate_perturbation_options!(num_perturbations, noise_level)
       when is_integer(num_perturbations) and num_perturbations > 0 and is_number(noise_level) and
              noise_level >= 0 and noise_level <= 1,
       do: :ok

  defp validate_perturbation_options!(num_perturbations, noise_level) do
    raise ArgumentError,
          "num_perturbations must be a positive integer and noise_level must be between 0 and 1; " <>
            "got: #{inspect(num_perturbations)}, #{inspect(noise_level)}"
  end

  defp validate_landscape_radius!(radius) when is_integer(radius) and radius >= 0, do: :ok

  defp validate_landscape_radius!(radius) do
    raise ArgumentError, "radius must be a non-negative integer, got: #{inspect(radius)}"
  end

  defp validate_matrix!(data) when is_list(data) do
    case data do
      [] ->
        :ok

      [first_row | rows] when is_list(first_row) ->
        width = length(first_row)

        unless Enum.all?(rows, &(is_list(&1) and length(&1) == width)) do
          raise ArgumentError, "2D input must be a rectangular matrix"
        end

        :ok

      _ ->
        raise ArgumentError, "2D input must be a list of rows"
    end
  end

  defp validate_matrix!(data) do
    raise ArgumentError, "2D input must be a list of rows, got: #{inspect(data)}"
  end

  defp effect_stats_2d(num_flips, [], sampled?) do
    %{
      num_flips: num_flips,
      max_effect: 0.0,
      min_effect: 0.0,
      avg_effect: 0.0,
      sample_count: 0,
      sampled: sampled?
    }
  end

  defp effect_stats_2d(num_flips, effects, sampled?) do
    max_effect = Enum.max(effects)
    min_effect = Enum.min(effects)
    avg_effect = Enum.sum(effects) / length(effects)

    %{
      num_flips: num_flips,
      max_effect: max_effect,
      min_effect: min_effect,
      avg_effect: avg_effect,
      sample_count: length(effects),
      sampled: sampled?
    }
  end
end
