defmodule Distopy.Presenter.CLI do
  import Distopy.Shell
  import Distopy.Source

  def print_missing(keys, dist_source, env_source) do
    # print error message to stderr but print the variables list to stdout so the
    # cli command can be piped to clipboard copy. stderr is slower than stdio so
    # we use a sleep()
    info([
      colored(display_name(env_source), :cyan),
      colored(" is missing one or more variables from ", :yellow),
      colored(display_name(dist_source), :magenta),
      colored(":", :yellow)
    ])

    # we will print the keys/values from the dist source, but the user will want
    # to add those values in the env source, so we pull the value from dist but
    # display in the env format.

    pairs =
      keys
      |> Enum.sort()
      |> Enum.map(&{&1, display_value(dist_source, &1)})

    varlist = [?\n, pairs_to_iodata(env_source, pairs), ?\n]

    warn(:stdio, varlist)
  end

  def print_extra(keys, dist_source, env_source) do
    # here we do the opposite of print_missing/3.
    info([
      colored(display_name(env_source), :cyan),
      colored(" has variables not defined in ", :yellow),
      colored(display_name(dist_source), :magenta),
      colored(":", :yellow)
    ])

    pairs =
      keys
      |> Enum.sort()
      |> Enum.map(&{&1, display_value(env_source, &1)})

    varlist = [?\n, pairs_to_iodata(dist_source, pairs), ?\n]

    warn(:stdio, varlist)
  end

  def print_sync_ok(dist_source, env_source) do
    success([
      display_name(env_source),
      " is in sync with ",
      display_name(dist_source)
    ])
  end

  def fix_missing(keys, dist_source, env_source) when is_list(keys) do
    Enum.reduce(keys, {_missing = env_source, _providing = dist_source}, fn key, sources ->
      fix_undef(key, sources, {:cyan, :magenta})
    end)
  end

  def fix_extra(keys, dist_source, env_source) when is_list(keys) do
    Enum.reduce(keys, {_missing = dist_source, _providing = env_source}, fn key, sources ->
      fix_undef(key, sources, {:magenta, :cyan})
    end)
  end

  defp fix_undef(
         key,
         {missing_source, providing_source} = state,
         {missing_color, providing_color} = colors
       ) do
    disp_miss = colored(display_name(missing_source), missing_color)
    disp_prov = colored(display_name(providing_source), providing_color)

    value_disp = display_value(providing_source, key)
    pair_display = pair_to_iodata(missing_source, key, value_disp)

    info([
      "fixing ",
      disp_miss,
      " missing ",
      colored(pair_display, :yellow)
    ])

    choice =
      build_choice([
        if updatable?(missing_source) do
          {?a, "add above value to #{disp_miss}", &fixer_add_value/2}
        end,
        if updatable?(missing_source) do
          {?e, "enter value for #{disp_miss}", &fixer_enter_value/2}
        end,
        if source_group?(missing_source) do
          {?c, "change target in #{disp_miss}", &fixer_change_missing_sub/2}
        end,
        if updatable?(providing_source) do
          {?d, "delete from #{disp_prov}", &fixer_remove_key(&1, &2, providing_color)}
        end,
        if source_group?(providing_source) do
          {?g, "change source in #{disp_prov}", &fixer_change_provider_sub/2}
        end,
        {?s, "skip", fn _, _ -> {:ok, state} end},
        {?q, "quit", fn _, _ -> abort(0) end}
      ])

    case run_choice(choice, [key, state]) do
      {:ok, state} -> state
      {:retry, state} -> fix_undef(key, state, colors)
      {:error, reason} -> abort(reason)
      other -> raise "invalid return value `#{inspect(other)}` from action"
    end
  end

  defp run_choice(%{actions: actions, display: display} = choice, action_args) do
    case IO.gets([display, ?\n, "> "]) |> String.trim() do
      <<letter>> when is_map_key(actions, letter) ->
        action = Map.fetch!(actions, letter)
        apply(action, action_args)

      _ ->
        warn("Eh?")
        run_choice(choice, action_args)
    end
  end

  defp build_choice(choices) when is_list(choices) do
    {revorder, iodata, actions} =
      Enum.reduce(choices, {[], [], []}, fn
        {letter, display, action}, {letters, iodata, actions}
        when letter in ?a..?z and is_function(action) ->
          {[letter | letters], [[?[, letter, ?], 32, display] | iodata],
           [{letter, action} | actions]}

        nil, acc ->
          acc
      end)

    %{
      actions: Map.new(actions),
      order: :lists.reverse(revorder),
      display: iodata |> :lists.reverse() |> Enum.intersperse(10)
    }
  end

  # fixers

  defp fixer_add_value(key, {missing_source, providing_source}) do
    value = get_value(providing_source, key)
    call_add_pair(missing_source, key, value, providing_source)
  end

  defp fixer_enter_value(key, {missing_source, providing_source}) do
    value = prompt_value(key)
    call_add_pair(missing_source, key, value, providing_source)
  end

  defp call_add_pair(missing_source, key, value, providing_source) do
    case add_pair(missing_source, key, value) do
      {:ok, missing_source} -> {:ok, {missing_source, providing_source}}
      {:error, reason} -> abort(reason)
    end
  end

  defp fixer_remove_key(key, {missing_source, providing_source}, color) do
    case delete_recursively(providing_source, key, color) do
      {:ok, providing_source} -> {:ok, {missing_source, providing_source}}
      {:error, reason} -> abort(reason)
    end
  end

  defp delete_recursively(providing_source, key, color) do
    # If the source is a group, it could have the key defined multiple times. So
    # we will loop on it until it has fully removed all definitions.  So we must
    # check if it still has the key.
    cond do
      not has_key?(providing_source, key) ->
        {:ok, providing_source}

      source_group?(providing_source) ->
        {group_key, sub} = get_sub_with_key(providing_source, key)

        case delete_recursively(sub, key, color) do
          {:ok, sub} ->
            providing_source
            |> put_sub(group_key, sub)
            |> delete_recursively(key, color)

          {:error, _} = err ->
            err
        end

      true ->
        case delete_key(providing_source, key) do
          {:ok, source} ->
            info(["deleted ", key, " from ", colored(display_name(source), color)])
            {:ok, source}

          {:error, _} = err ->
            err
        end
    end
  end

  defp fixer_change_missing_sub(_key, {missing_source, providing_source}) do
    {:retry, {change_source(missing_source), providing_source}}
  end

  defp fixer_change_provider_sub(_key, {missing_source, providing_source}) do
    {:retry, {missing_source, change_source(providing_source)}}
  end

  defp change_source(group) do
    group
    |> list_sources()
    |> Enum.with_index(?a)
    |> Enum.map(fn {{group_key, sub_display}, letter} ->
      {
        letter,
        [if(selected?(group, group_key), do: "* ", else: "  "), sub_display],
        fn group -> select_source(group, group_key) end
      }
    end)
    |> build_choice()
    |> run_choice([group])
  end

  defp prompt_value(key) do
    IO.gets("enter value for #{key}: ") |> String.trim()
  end
end
