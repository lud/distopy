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
    Enum.reduce(keys, {_missing = env_source, _providing = dist_source}, &fix_undef/2)
  end

  def fix_extra(keys, dist_source, env_source) when is_list(keys) do
    Enum.reduce(keys, {_missing = dist_source, _providing = env_source}, &fix_undef/2)
  end

  defp fix_undef(key, {missing_source, providing_source} = state) do
    disp_miss = display_name(missing_source)
    disp_prov = display_name(providing_source)

    value_disp = display_value(providing_source, key)
    pair_display = pair_to_iolist(missing_source, key, value_disp)

    info([
      "fixing ",
      disp_miss,
      " missing ",
      colored(pair_display, :yellow)
    ])

    choice =
      build_choice([
        if updatable?(missing_source) do
          {?a, "add above value to #{disp_miss}",
           fn key, {missing_source, providing_source} = state ->
             value = get_value(providing_source, key)

             case add_pair(missing_source, key, value) do
               {:ok, missing_source} -> {:ok, {missing_source, providing_source}}
               {:error, reason} -> abort(reason)
             end
           end}
        end,
        if updatable?(missing_source) do
          {?e, "enter value for #{disp_miss}",
           fn key, {missing_source, providing_source} = state ->
             value = prompt_value(key)

             case add_pair(missing_source, key, value) do
               {:ok, missing_source} -> {:ok, {missing_source, providing_source}}
               {:error, reason} -> abort(reason)
             end
           end}
        end,
        if updatable?(providing_source) do
          {?d, "delete from #{disp_prov}",
           fn key, {missing_source, providing_source} = state ->
             case delete_key(providing_source, key) do
               {:ok, providing_source} -> {:ok, {missing_source, providing_source}}
               {:error, reason} -> abort(reason)
             end
           end}
        end,
        if source_group?(missing_source) do
          {?c, "change target file from #{disp_miss}",
           fn key, {missing_source, providing_source} = state ->
             missing_source =
               missing_source
               |> list_sources()
               |> Enum.with_index(?a)
               |> Enum.map(fn {{sub_key, sub_display}, letter} ->
                 {letter, sub_display, fn missing -> select_source(missing, sub_key) end}
               end)
               |> build_choice()
               |> run_choice([missing_source])

             {:retry, {missing_source, providing_source}}
           end}
        end,
        {?s, "skip", fn _, _ -> {:ok, state} end},
        {?q, "quit", fn _, _ -> abort(0) end}
      ])

    case run_choice(choice, [key, state]) do
      {:ok, state} -> state
      {:retry, state} -> fix_undef(key, state)
      {:error, reason} -> abort(reason)
      other -> raise "invalid return value `#{inspect(other)}` from action"
    end
  end

  defp run_choice(%{actions: actions, display: display} = choice, args) do
    case IO.gets([display, ?\n, "> "]) |> String.trim() do
      <<letter>> when is_map_key(actions, letter) ->
        action = Map.fetch!(actions, letter)
        apply(action, args)

      _ ->
        warn("Eh?")
        run_choice(choice, args)
    end
  end

  defp build_choice(choices) when is_list(choices) do
    {revorder, iolist, actions} =
      Enum.reduce(choices, {[], [], []}, fn
        {letter, display, action}, {letters, iolist, actions}
        when letter in ?a..?z and is_function(action) ->
          {[letter | letters], [[?[, letter, ?], 32, display] | iolist],
           [{letter, action} | actions]}

        nil, acc ->
          acc
      end)

    %{
      actions: Map.new(actions),
      order: :lists.reverse(revorder),
      display: iolist |> :lists.reverse() |> Enum.intersperse(10)
    }
  end

  defp prompt_value(key) do
    IO.gets("enter value for #{key}: ") |> String.trim()
  end
end
