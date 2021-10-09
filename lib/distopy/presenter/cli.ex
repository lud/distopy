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
      |> Enum.map(&{&1, get_value!(dist_source, &1)})

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
      |> Enum.map(&{&1, get_value!(env_source, &1)})

    varlist = [?\n, pairs_to_iolist(dist_source, pairs), ?\n]

    warn(:stdio, varlist)
  end
end
