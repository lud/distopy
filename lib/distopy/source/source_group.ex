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
  def list_keys(t) do
    t
    |> flat_map(&Source.list_keys/1)
    |> Enum.uniq()
  end

  @spec source_group?(t) :: boolean
  def source_group?(_t), do: true

  @spec updatable?(t) :: boolean
  def updatable?(t), do: with_selected(t, &Source.updatable?/1)

  @spec list_sources(t) :: [{group_key :: term, display_name :: iolist}]
  def list_sources(t), do: fmap(t, &Source.display_name/1)

  @spec select_source(t, group_key :: term) :: t
  def select_source(%{sources: sources} = t, key) when is_map_key(sources, key),
    do: %SourceGroup{t | selected: key}

  @spec display_name(t) :: iolist
  def display_name(%{sources: sources} = t) do
    n = map_size(sources) - 1
    [with_selected(t, Source.display_name() / 1), " (+", Integer.to_charlist(n), ")"]
  end

  @spec get_value(t, key :: binary) :: binary
  def get_value(t, key) do
    {_, val} = get_sub_with_value(t, key)
    val
  end

  @spec display_value(t, key :: binary) :: iolist
  def display_value(t, key) do
    {sub, _} = get_sub_with_value(t, key)
    Source.display_value(sub, key)
  end

  defp get_sub_with_value(%{sources: sources} = t, key) do
    # if the value is in multiple sub sources prefer the selected one.
    selected = selected(t)

    if Source.has_key?(selected, key) do
      {selected, Source.get_value(selected, key)}
    else
      Enum.find(sources, fn {_, sub} ->
        Source.has_key(sub, key) && {sub, Source.get_value(sub, key)}
      end)
    end
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

  @spec pairs_to_iolist(t, [{key :: binary, value :: iolist}]) :: iolist
  def pairs_to_iolist(t, pairs) do
    with_selected(t, &Source.pairs_to_iolist(&1, pairs))
  end

  @spec pair_to_iolist(t, key :: binary, value :: iolist) :: iolist
  def pair_to_iolist(t, key, value) do
    with_selected(t, &Source.pair_to_iolist(&1, key, value))
  end

  # pass each source to the callback, return with keys
  defp fmap(%{sources: sources}, f) when is_function(f, 1),
    do: Enum.map(sources, fn {key, sub} -> {key, f.(sub)} end)

  # pass each source to the callback, flattens the result
  defp flat_map(%{sources: sources}, f) when is_function(f, 1),
    do: Enum.flat_map(sources, fn {_, sub} -> f.(sub) end)

  # pass each {key, source} to the callback
  defp map_sources(%{sources: sources}, f) when is_function(f, 1),
    do: Enum.map(sources, f)

  defp with_selected(%{sources: sources, selected: sel}, f),
    do: sources |> Map.fetch!(sel) |> then(f)

  defp replace_selected(%{sources: sources, selected: sel} = t, new_sub) do
    %SourceGroup{t | sources: Map.put(sources, sel, new_sub)}
  end

  defp selected(%{sources: sources, selected: sel}),
    do: sources |> Map.fetch!(sel)
end
