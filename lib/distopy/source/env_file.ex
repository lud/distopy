defmodule Distopy.Source.EnvFile do
  @enforce_keys [:path, :vars, :hide_values]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          path: binary,
          vars: %{optional(binary) => binary},
          hide_values: boolean
        }

  def new(path, opts \\ []) do
    if File.regular?(path) do
      case Dotenvy.source([path], side_effect: false, vars: %{}) do
        {:ok, vars} ->
          if Keyword.has_key?(opts, :color), do: raise("color deprecated")

          %__MODULE__{
            path: path,
            vars: vars,
            hide_values: !!Keyword.get(opts, :hide_values)
          }

        {:error, reason} ->
          raise "could not load env file #{path}: #{inspect(reason)}"
      end
    else
      raise "could not load env file #{path}: file not found"
    end
  end
end

defimpl Distopy.Source, for: Distopy.Source.EnvFile do
  alias Distopy.Source.EnvFile
  use Distopy.Source.BaseFile

  @type t :: EnvFile.t()

  @spec list_keys(t) :: [binary]
  def list_keys(t), do: Map.keys(t.vars)

  @spec has_key?(t, key :: binary) :: boolean
  def has_key?(t, key), do: Map.has_key?(t.vars, key)

  @spec updatable?(t) :: boolean
  def updatable?(_), do: true

  @spec display_name(t) :: iodata
  def display_name(%{path: path}),
    do: path

  @spec get_value(t, key :: binary()) :: binary()
  def get_value(%{vars: vars}, key) when is_map_key(vars, key),
    do: Map.fetch!(vars, key)

  def get_value(t, key),
    do: invalid_key!(t, key)

  @spec display_value(t, key :: binary) :: iodata
  def display_value(%{hide_values: hide?} = t, key) do
    value = get_value(t, key)

    if hide?, do: "**********", else: value
  end

  @spec add_pair(t, key :: binary, value :: binary) :: {:ok, t} | {:error, binary}
  def add_pair(t, key, value) do
    :ok = put_value(t, key, value)
    {:ok, update_in(t.vars, &Map.put(&1, key, value))}
  end

  @spec delete_key(t, key :: binary) :: {:ok, t} | {:error, binary}
  def delete_key(t, key) do
    :ok = remove_key(t, key)
    {:ok, update_in(t.vars, &Map.delete(&1, key))}
  end

  @spec pairs_to_iodata(t, [{key :: binary, value :: iodata}]) :: iodata
  def pairs_to_iodata(t, pairs) do
    pairs
    |> Enum.map(fn {k, v} -> pair_to_iodata(t, k, v) end)
    |> Enum.intersperse("\n")
  end

  @spec pair_to_iodata(t, key :: binary, value :: iodata) :: iodata
  def pair_to_iodata(_t, key, value) do
    [key, "=", value]
  end

  defp put_value(%{path: path} = t, key, value) do
    nl? = ends_with_nl?(path)

    f = File.open!(path, [:append])
    if not nl?, do: IO.write(f, "\n")
    IO.puts(f, pair_to_iodata(t, key, value))
    :ok = File.close(f)
  end

  defp remove_key(%{path: path}, key) do
    path
    |> File.stream!()
    |> Enum.filter(
      &if String.starts_with?(&1, "#{key}=") do
        false
      else
        true
      end
    )
    |> Enum.into(File.stream!(path))

    :ok
  end

  defp ends_with_nl?(file) do
    file
    |> File.stream!()
    |> Enum.at(-1)
    |> case do
      nil ->
        false

      line ->
        line
        |> String.at(-1)
        |> Kernel.==("\n")
    end
  end
end

defimpl Inspect, for: Distopy.Source.EnvFile do
  def inspect(ef, _), do: "#EnvFile<#{ef.path}>"
end
