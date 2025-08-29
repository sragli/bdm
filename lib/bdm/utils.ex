defmodule BDM.Utils do
  @moduledoc false

  def csv_to_etf_and_save(csv_file, etf_file) do
    bin =
      csv_file
      |> File.stream!()
      |> Stream.map(&String.split(&1, ","))
      |> Stream.map(fn [s, k] ->
        {
          s |> String.graphemes() |> Enum.map(&String.to_integer/1),
          k |> Float.parse() |> elem(0)
        }
      end)
      |> Enum.into(%{})
      |> :erlang.term_to_binary([:compressed])

    File.write!(etf_file, bin)
  end
end
