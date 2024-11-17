defmodule Distopy.Source.SourceGroup do
  @enforce_keys [:sources, :color, :selected]
  defstruct @enforce_keys

  def new(sources, opts \\ []) when is_map(sources) and map_size(sources) > 0 and is_list(opts) do
    %__MODULE__{
      sources: sources,
      color: Keyword.get(opts, :color, :cyan),
      selected: sources |> Map.keys() |> hd()
    }
  end
end

defimpl Distopy.Source, for: Distopy.Source.SourceGroup do
  alias Distopy.Source
  alias Distopy.Source.SourceGroup

  @type t :: %SourceGroup{}

  @spec list_keys(t) :: [binary]
  def list_keys(%{sources: sources}) do
    sources
    |> Enum.flat_map(vmapper(&Source.list_keys/1))
    |> Enum.uniq()
  end

  @spec has_key?(t, key :: binary) :: boolean
  def has_key?(%{sources: sources}, key) do
    Enum.any?(sources, fn {_, sub} -> Source.has_key?(sub, key) end)
  end

  @spec source_group?(t) :: boolean
  def source_group?(_t), do: true

  @spec updatable?(t) :: boolean
  def updatable?(t), do: with_selected(t, &Source.updatable?/1)

  @spec list_sources(t) :: [{group_key :: term, display_name :: iodata}]
  def list_sources(%{sources: sources}),
    do: Enum.map(sources, pkmapper(&Source.display_name/1))

  @spec select_source(t, group_key :: term) :: t
  def select_source(%{sources: sources} = t, key) when is_map_key(sources, key),
    do: %SourceGroup{t | selected: key}

  @spec selected?(t, group_key :: term) :: boolean
  def selected?(%{selected: sel}, group_key),
    do: sel == group_key

  @spec display_name(t) :: iodata
  def display_name(%{sources: sources, selected: sel}) do
    selected = Map.fetch!(sources, sel)
    other_sources = sources |> Map.delete(sel) |> Map.values()

    selected_name = [Source.display_name(selected), ?*]
    other_names = Enum.map(other_sources, &Source.display_name/1)

    names = Enum.intersperse([selected_name | other_names], ", ")

    ["group [", names, "]"]
  end

  @spec get_value(t, key :: binary) :: binary
  def get_value(t, key) do
    {_, sub} = get_sub_with_key(t, key)
    Source.get_value(sub, key)
  end

  @spec display_value(t, key :: binary) :: iodata
  def display_value(t, key) do
    {_, sub} = get_sub_with_key(t, key)
    Source.display_value(sub, key)
  end

  @spec get_sub_with_key(t, key :: binary) :: {group_key :: term, sub_source :: term}
  def get_sub_with_key(%{sources: sources, selected: sel}, key) do
    # if the key is defined in multiple sub sources, prefer the selected one.
    selected = Map.fetch!(sources, sel)

    if Source.has_key?(selected, key) do
      {sel, selected}
    else
      Enum.find(sources, fn {_, sub} -> Source.has_key?(sub, key) end)
    end
  end

  @spec put_sub(t, group_key :: term, sub_source :: term) :: t
  def put_sub(%{sources: sources} = t, group_key, sub_source)
      when is_map_key(sources, group_key) do
    %SourceGroup{t | sources: Map.put(sources, group_key, sub_source)}
  end

  @spec add_pair(t, key :: binary, value :: binary) :: {:ok, t} | {:error, binary}
  def add_pair(t, key, value) do
    case with_selected(t, &Source.add_pair(&1, key, value)) do
      {:ok, sub} -> {:ok, replace_selected(t, sub)}
      other -> other
    end
  end

  @spec delete_key(t, key :: binary) :: {:ok, t} | {:error, binary}
  def delete_key(t, key) do
    case with_selected(t, &Source.delete_key(&1, key)) do
      {:ok, sub} -> {:ok, replace_selected(t, sub)}
      other -> other
    end
  end

  @spec pairs_to_iodata(t, [{key :: binary, value :: iodata}]) :: iodata
  def pairs_to_iodata(t, pairs) do
    with_selected(t, &Source.pairs_to_iodata(&1, pairs))
  end

  @spec pair_to_iodata(t, key :: binary, value :: iodata) :: iodata
  def pair_to_iodata(t, key, value) do
    with_selected(t, &Source.pair_to_iodata(&1, key, value))
  end

  # enum values mapper
  defp vmapper(f) when is_function(f, 1), do: fn {_, v} -> f.(v) end

  # preserve enum keys mapper
  defp pkmapper(f) when is_function(f, 1), do: fn {k, v} -> {k, f.(v)} end

  defp with_selected(%{sources: sources, selected: sel}, f),
    do: sources |> Map.fetch!(sel) |> then(f)

  defp replace_selected(%{sources: sources, selected: sel} = t, new_sub) do
    %SourceGroup{t | sources: Map.put(sources, sel, new_sub)}
  end
end

defimpl Inspect, for: Distopy.Source.SourceGroup do
  def inspect(sg, opts) do
    selected = Map.fetch!(sg.sources, sg.selected)
    n = map_size(sg.sources) - 1
    "#SourceGroup<[#{Inspect.inspect(selected, opts)} (+#{n})]>"
  end
end
