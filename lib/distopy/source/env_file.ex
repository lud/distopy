defmodule Distopy.Source.EnvFile do
  @enforce_keys [:path, :vars, :hide_values, :color]
  defstruct @enforce_keys

  def new(path, opts \\ []) do
    if File.regular?(path) do
      case Dotenvy.source([path], side_effect: false, vars: %{}) do
        {:ok, vars} ->
          %__MODULE__{
            path: path,
            vars: vars,
            hide_values: !!Keyword.get(opts, :hide_values),
            color: Keyword.get(opts, :color, :cyan)
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
  import Distopy.Source.Helpers

  @type t :: %EnvFile{}

  @spec list_keys(t) :: [binary]
  def list_keys(t), do: Map.keys(t.vars)

  @spec source_group?(t) :: boolean
  def source_group?(_), do: false

  @spec updatable?(t) :: boolean
  def updatable?(_), do: true

  @spec list_sources(t) :: [{group_key :: term, display_name :: iolist}]
  def list_sources(_),
    do: invalid_group!()

  @spec select_source(t, group_key :: term) :: t
  def select_source(t, source),
    do: invalid_group!()

  @spec group_key(t) :: term
  def group_key(t), do: t.path

  @spec display_name(t) :: iolist
  def display_name(t),
    do: [Distopy.Shell.colored(t.path, t.color)]

  @spec get_value(t, key :: binary()) :: binary()
  def get_value(t, key) when is_map_key(t.vars, key),
    do: Map.fetch!(t.vars, key)

  def get_value(t, key) when is_map_key(t.vars, key),
    do: invalid_key!(t, key)

  @spec display_value(t, key :: binary) :: iolist
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

  @spec pairs_to_iolist(t, [{key :: binary, value :: iolist}]) :: iolist
  def pairs_to_iolist(t, pairs) do
    pairs
    |> Enum.map(fn {k, v} -> pair_to_iolist(t, k, v) end)
    |> Enum.intersperse("\n")
  end

  @spec pair_to_iolist(t, key :: binary, value :: iolist) :: iolist
  def pair_to_iolist(_t, key, value) do
    [key, "=", value]
  end

  defp put_value(%{path: path} = t, key, value) do
    nl? = ends_with_nl?(path)

    f = File.open!(path, [:append])
    if not nl?, do: IO.write(f, "\n")
    IO.puts(f, pair_to_iolist(t, key, value))
    :ok = File.close(f)
  end

  defp remove_key(%{path: path} = t, key) do
    path
    |> File.stream!()
    |> Enum.filter(
      &if String.starts_with?(&1, "#{key}=") do
        IO.puts(["removing #{key} from ", display_name(t)])
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
    |> String.at(-1)
    |> Kernel.==("\n")
  end
end
