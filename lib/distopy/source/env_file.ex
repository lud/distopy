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

  @spec list_sources(t) :: [{group_key :: term, display_name :: iolist()}]
  def list_sources(_),
    do: invalid_group!()

  @spec select_source(t, group_key :: term) :: t
  def select_source(t, source),
    do: invalid_group!()

  @spec group_key(t) :: term
  def group_key(t), do: t.path

  @spec display_name(t) :: iolist()
  def display_name(t),
    do: [Distopy.Shell.colored(t.path, t.color)]

  @spec get_value!(t, key :: binary) :: binary
  def get_value!(t, key) when is_map_key(t.vars, key) and not t.hide_values,
    do: Map.fetch!(t.vars, key)

  def get_value!(t, key) when is_map_key(t.vars, key),
    do: "**********"

  def get_value!(t, key) when is_map_key(t.vars, key),
    do: invalid_key!(t, key)

  @spec add_pair(t, key :: binary, value :: binary) :: {:ok, t} | {:error, binary}
  def add_pair(t, key, value) do
    raise "not implemented"
  end

  @spec delete_key(t, key :: binary) :: {:ok, t} | {:error, binary}
  def delete_key(t, key) do
    raise "not implemented"
  end

  @spec pairs_to_iolist(t, [{key :: binary, value :: binary}]) :: iolist()
  def pairs_to_iolist(_, pairs) do
    pairs
    |> Enum.map(fn {k, v} -> [k, "=", v] end)
    |> Enum.intersperse("\n")
  end
end