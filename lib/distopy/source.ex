defprotocol Distopy.Source do
  @spec list_keys(t) :: [binary]
  def list_keys(t)

  @spec has_key?(t, key :: binary) :: boolean
  def has_key?(t, key)

  @spec source_group?(t) :: boolean
  def source_group?(t)

  @spec updatable?(t) :: boolean
  def updatable?(t)

  @spec list_sources(t) :: [{group_key :: term, display_name :: iodata}]
  def list_sources(t)

  @spec select_source(t, group_key :: term) :: t
  def select_source(t, source)

  @doc """
  Returns wether the currently selected sub-source in group is the given
  `group_key`. The group key is the one returned from `get_sub_with_key/2` or
  `list_source/1`.
  """
  @doc group: true
  @spec selected?(t, group_key :: term) :: boolean
  def selected?(t, source)

  @spec display_name(t) :: iodata
  def display_name(t)

  @spec get_value(t, key :: binary) :: binary
  def get_value(t, key)

  @doc """
  Returns the sub-source that defines the key `key`. The function must return
  a tuple with `group_key` as an unique identifier of the sub-source in the
  group, and the sub-source itself.

  Do not mistake `key` for `group_key`. The former indetifies an environment
  variable name while the latter identifies a sub-source in a group.
  """
  @doc group: true
  @spec get_sub_with_key(t, key :: binary) :: {group_key :: term, sub_source :: term}
  def get_sub_with_key(t, key)

  @doc """
  Replaces the sub-source uniquely identified by `group_key`. The given group
  key is the one returned from `get_sub_with_key/2` or `list_source/1`.
  """
  @doc group: true
  @spec put_sub(t, group_key :: term, sub_source :: term) :: t
  def put_sub(t, group_key, sub_source)

  @spec display_value(t, key :: binary) :: iodata
  def display_value(t, key)

  @spec add_pair(t, key :: binary, value :: binary) :: {:ok, t} | {:error, binary}
  def add_pair(t, key, value)

  @spec delete_key(t, key :: binary) :: {:ok, t} | {:error, binary}
  def delete_key(t, key)

  @spec pairs_to_iodata(t, [{key :: binary, value :: iodata}]) :: iodata
  def pairs_to_iodata(t, pairs)

  @spec pair_to_iodata(t, key :: binary, value :: iodata) :: iodata
  def pair_to_iodata(t, key, value)
end

defmodule Distopy.Source.Helpers do
  defmacro invalid_group!() do
    quote do
      {f, a} = __ENV__.function

      raise "cannot use %#{inspect(__MODULE__)}{} as a sources group, attempted to call Distopy.Source.#{Atom.to_string(f)}/#{a}"
    end
  end

  defmacro invalid_key!(t, key) do
    quote do
      errmsg =
        to_string([
          Distopy.Source.display_name(unquote(t)),
          " does not have key ",
          ?",
          unquote(key),
          ?"
        ])

      raise ArgumentError, message: errmsg
    end
  end
end
