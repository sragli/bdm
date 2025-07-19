defmodule BDM.PerturbationAnalysis do
  @moduledoc """
  Tools for analyzing how perturbations affect BDM complexity estimates.
  """

  @doc """
  Generate all possible single-bit flip perturbations of the data.
  """
  def single_bit_perturbations(data) do
    for i <- 0..(length(data) - 1) do
      data
      |> List.update_at(i, fn bit -> 1 - bit end)
    end
  end

  @doc """
  Generate random perturbations with specified noise level.
  noise_level: fraction of bits to flip (0.0 to 1.0)
  """
  def random_perturbations(data, num_perturbations, noise_level) do
    data_length = length(data)
    num_flips = round(data_length * noise_level)

    for _ <- 1..num_perturbations do
      positions = Enum.take_random(0..(data_length - 1), num_flips)

      Enum.reduce(positions, data, fn pos, acc ->
        List.update_at(acc, pos, fn bit -> 1 - bit end)
      end)
    end
  end

  @doc """
  Calculate BDM for original and all perturbed versions.
  """
  def calculate_perturbation_effects(bdm, original_data, perturbations, block_size \\ 3, boundary \\ :ignore) do
    original_bdm = BDM.compute(bdm, original_data, block_size, boundary)

    perturbation_results =
      perturbations
      |> Enum.with_index()
      |> Enum.map(fn {perturbed_data, index} ->
        perturbed_bdm = BDM.compute(bdm, perturbed_data, block_size, boundary)
        delta_bdm = perturbed_bdm - original_bdm

        %{
          index: index,
          original_bdm: original_bdm,
          perturbed_bdm: perturbed_bdm,
          delta_bdm: delta_bdm,
          relative_change: delta_bdm / original_bdm
        }
      end)

    {original_bdm, perturbation_results}
  end

  @doc """
  Create a sensitivity profile showing which positions are most sensitive to perturbation.
  """
  def sensitivity_profile(bdm, data, block_size \\ 3, boundary \\ :ignore) do
    single_perturbations = single_bit_perturbations(data)
    {_, results} = calculate_perturbation_effects(bdm, data, single_perturbations, block_size, boundary)

    results
    |> Enum.map(fn result ->
      %{
        position: result.index,
        sensitivity: abs(result.delta_bdm),
        relative_sensitivity: abs(result.relative_change)
      }
    end)
  end

  @doc """
  Identify positions where perturbation sensitivity exceeds threshold.
  """
  def detect_critical_positions(sensitivity_profile, threshold \\ 1.0) do
    sensitivity_profile
    |> Enum.filter(fn point -> point.sensitivity > threshold end)
    |> Enum.sort_by(& &1.sensitivity, :desc)
  end

  @doc """
  Create a landscape showing cumulative effects of multi-bit perturbations.
  """
  def perturbation_landscape(bdm, data, radius \\ 2, block_size \\ 3, boundary \\ :ignore) do
    original_bdm = BDM.compute(bdm, data, block_size, boundary)

    data_length = length(data)

    # Generate perturbations in a sliding window
    for center <- radius..(data_length - radius - 1) do
      positions = (center - radius)..(center + radius) |> Enum.to_list()

      # Try all combinations of flips in this window
      perturbation_effects =
        for num_flips <- 1..length(positions) do
          combinations = combinations(positions, num_flips)

          # Limit for performance
          effects =
            for combination <- Enum.take(combinations, 10) do
              perturbed_data = flip_positions(data, combination)
              perturbed_bdm = BDM.compute(bdm, perturbed_data, 3, :ignore)
              perturbed_bdm - original_bdm
            end

          max_effect = if effects != [], do: Enum.max(effects), else: 0.0
          %{center: center, num_flips: num_flips, max_effect: max_effect}
        end

      %{center: center, effects: perturbation_effects}
    end
  end

  defp combinations(_, 0), do: [[]]
  defp combinations([], _), do: []

  defp combinations([h | t], n) do
    for(l <- combinations(t, n - 1), do: [h | l]) ++ combinations(t, n)
  end

  @doc """
  Calculate stability coefficient: ratio of consistent complexity estimates.
  """
  def stability_coefficient(bdm, data, num_trials \\ 50, noise_level \\ 0.1, block_size \\ 3, boundary \\ :ignore) do
    original_bdm = BDM.compute(bdm, data, block_size, boundary)

    perturbations = random_perturbations(data, num_trials, noise_level)

    {_, results} = calculate_perturbation_effects(bdm, data, perturbations)

    # Calculate coefficient of variation
    delta_bdms = Enum.map(results, &(&1.delta_bdm))
    mean_delta = Enum.sum(delta_bdms) / length(delta_bdms)
    variance = Enum.sum(Enum.map(delta_bdms, fn x -> (x - mean_delta) * (x - mean_delta) end)) / length(delta_bdms)
    std_dev = :math.sqrt(variance)

    coefficient_of_variation = if mean_delta != 0, do: std_dev / abs(mean_delta), else: 0.0

    %{
      original_bdm: original_bdm,
      mean_perturbation_effect: mean_delta,
      std_perturbation_effect: std_dev,
      coefficient_of_variation: coefficient_of_variation,
      stability_score: 1.0 / (1.0 + coefficient_of_variation)  # Higher is more stable
    }
  end

  defp flip_positions(data, positions) do
    Enum.reduce(positions, data, fn pos, acc ->
      List.update_at(acc, pos, fn bit -> 1 - bit end)
    end)
  end
end
