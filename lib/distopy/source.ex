defprotocol Distopy.Source do
  @doc """
  Returns the list of environment variable names defined in the source.
  """
  @spec list_keys(t) :: [binary]
  def list_keys(t)

  @doc """
  Returns wether the given environment variable is defined in the source.
  """
  @spec has_key?(t, key :: binary) :: boolean
  def has_key?(t, key)

  @doc """
  Returns wether the source has sub-sources, _i.e._ is a group of sources.
  """
  @spec source_group?(t) :: boolean
  def source_group?(t)

  @doc """
  Returns wether the source can be modified by adding or remomving environment
  variables.
  """
  @spec updatable?(t) :: boolean
  def updatable?(t)

  @doc """
  Returns the name of the source for display purposes.
  """
  @spec display_name(t) :: iodata
  def display_name(t)

  @doc """
  Get the value associated to the environment variables identified by `key`.
  It should raise if the variable is not defined.
  """
  @spec get_value(t, key :: binary) :: binary
  def get_value(t, key)

  @doc """
  Returns the reprensentation of a value for display purposes. Instead of
  returning the raw binary value, it is possible to return text like
  `"hidden value"`, a parsed reprensentation of a JSON string, _etc_.
  """
  @spec display_value(t, key :: binary) :: iodata
  def display_value(t, key)

  @doc """
  Creates a new environment variable in the source. It will only be called if
  the source returns `true` from `updatable?/1`.
  """
  @spec add_pair(t, key :: binary, value :: binary) :: {:ok, t} | {:error, binary}
  def add_pair(t, key, value)

  @doc """
  Deletes the environment variable identified by `key` in the source.
  """
  @spec delete_key(t, key :: binary) :: {:ok, t} | {:error, binary}
  def delete_key(t, key)

  @doc """
  Returns a displayable version of the given list of environment variables keys
  and values.

  The keys may or may not be defined in the source as the values are passed to
  the function.
  """
  @spec pairs_to_iodata(t, [{key :: binary, value :: iodata}]) :: iodata
  def pairs_to_iodata(t, pairs)

  @doc """
  Represents a single key/value pair for display purposes.

  See `pairs_to_iodata/2`.
  """
  @spec pair_to_iodata(t, key :: binary, value :: iodata) :: iodata
  def pair_to_iodata(t, key, value)

  @doc """
  Returns a list of sub-sources identified by an unique "group" key.
  """
  @doc group: true
  @spec list_sources(t) :: [{group_key :: term, display_name :: iodata}]
  def list_sources(t)

  @doc """
  Sets the current selected source identified by `group_key`.  A group of
  sources shoud add new environment variables to the currently selected sub.
  """
  @doc group: true
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

  @doc """
  Returns the sub-source that defines the key `key`. The function must return
  a tuple with `group_key` as an unique identifier of the sub-source in the
  group, and the sub-source itself.

  Do not mistake `key` for `group_key`. The former identifies an environment
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
