defprotocol Distopy.Source do
  @spec list_keys(t) :: [binary]
  def list_keys(t)

  @spec source_group?(t) :: boolean
  def source_group?(t)

  @spec updatable?(t) :: boolean
  def updatable?(t)

  @spec list_sources(t) :: [{group_key :: term, display_name :: iolist()}]
  def list_sources(t)

  @spec select_source(t, group_key :: term) :: t
  def select_source(t, source)

  @spec group_key(t) :: term
  def group_key(t)

  @spec display_name(t) :: iolist()
  def display_name(t)

  @spec get_value!(t, key :: binary) :: binary
  def get_value!(t, key)

  @spec add_pair(t, key :: binary, value :: binary) :: {:ok, t} | {:error, binary}
  def add_pair(t, key, value)

  @spec delete_key(t, key :: binary) :: {:ok, t} | {:error, binary}
  def delete_key(t, key)

  @spec pairs_to_iolist(t, [{key :: binary, value :: binary}]) :: iolist()
  def pairs_to_iolist(t, pairs)
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
