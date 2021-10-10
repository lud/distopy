defmodule Distopy.Presenter.CLI do
  import Distopy.Shell
  import Distopy.Source

  def print_missing(keys, dist_source, env_source) do
    # print error message to stderr but print the variables list to stdout so the
    # cli command can be piped to clipboard copy. stderr is slower than stdio so
    # we use a sleep()
    info([
      display_name(env_source),
      colored(" is missing one or more variables from ", :yellow),
      display_name(dist_source),
      colored(":", :yellow)
    ])

    # we will print the keys/values from the dist source, but the user will want
    # to add those values in the env source, so we pull the value from dist but
    # display in the env format.

    pairs =
      keys
      |> Enum.sort()
      |> Enum.map(&{&1, display_value(dist_source, &1)})

    varlist = [?\n, pairs_to_iolist(env_source, pairs), ?\n]

    warn(:stdio, varlist)
  end

  def print_extra(keys, dist_source, env_source) do
    # here we do the opposite of print_missing/3.
    info([
      display_name(env_source),
      colored(" has variables not defined in ", :yellow),
      display_name(dist_source),
      colored(":", :yellow)
    ])

    pairs =
      keys
      |> Enum.sort()
      |> Enum.map(&{&1, display_value(env_source, &1)})

    varlist = [?\n, pairs_to_iolist(dist_source, pairs), ?\n]

    warn(:stdio, varlist)
  end

  def print_sync_ok(dist_source, env_source) do
    info([
      display_name(env_source),
      colored(" is in sync with ", :green),
      display_name(dist_source)
    ])
  end

  def fix_missing(keys, dist_source, env_source) when is_list(keys) do
    Enum.map(keys, &fix_undef(&1, env_source, dist_source))
  end

  defp fix_undef(key, missing_source, providing_source) do
    value = get_value(providing_source, key)
    value_disp = display_value(providing_source, key)
    pair_display = pair_to_iolist(missing_source, key, value_disp)

    info([
      "fixing ",
      display_name(missing_source),
      " missing ",
      colored(pair_display, :yellow)
    ])

    todo("""
    provide choices depending on the sources
    - if missing_source is updatable, [a] add actual value (not display) from provider
    - if missing_source is updatable, [e] prompt value
    - if providing_source is updatable, [d] delete value from provider
    - if providing_source is updatable, [d] delete value from provider
    - if missing_source is a group, [c] change missing source
    - if providing_source is a group, [x] change providing source
    - [s] skip, [q] quit
    """)
  end
end
