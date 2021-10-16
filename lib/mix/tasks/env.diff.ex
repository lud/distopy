defmodule Mix.Tasks.Env.Diff do
  use Mix.Task
  import Distopy.Shell
  alias Distopy.Source.{EnvFile, SourceGroup}

  @version Distopy.MixProject.project() |> Keyword.fetch!(:version)

  @args_schema [dist: [:string, :keep], file: [:string, :keep], fix: :boolean]

  @impl true
  def run(argv) do
    argv |> parse_args() |> do_run()
  end

  defp parse_args(argv) do
    case OptionParser.parse(argv, strict: @args_schema) do
      {opts, [], []} ->
        opts
        |> collect_opts()
        |> check_opts()

      invalid ->
        print_usage()
        print_invalid_argv(invalid)
        abort()
    end
  end

  defp collect_opts(optslist) do
    optslist
    |> Enum.reduce(
      %{env_files: [], dist_files: [], fix: false},
      fn
        {:file, file}, acc -> add_file(acc, :env_files, file)
        {:dist, file}, acc -> add_file(acc, :dist_files, file)
        {:fix, v}, acc when is_boolean(v) -> Map.put(acc, :fix, v)
      end
    )
  end

  defp check_opts(%{env_files: env_files}) when length(env_files) < 1,
    do: abort("no file to check")

  defp check_opts(%{dist_files: dist}) when length(dist) < 1,
    do: abort("no dist file provided")

  defp check_opts(fine_opts),
    do: fine_opts

  defp add_file(acc, key, file) do
    if File.regular?(file) do
      Map.update!(acc, key, &(&1 ++ [file]))
    else
      warn("file #{file} not found")
      acc
    end
  end

  defp print_invalid_argv({_, [], invalid}) do
    invalid
    |> Enum.map(&elem(&1, 0))
    |> Enum.map(&to_string/1)
    |> case do
      [single] -> error("unknown option #{single}")
      more -> error("unknown options #{Enum.join(more, ", ")}")
    end
  end

  defp print_invalid_argv({_, _, _}) do
    error("no arguments are expected")
  end

  defp print_usage do
    """

    #{to_string(colored("mix env.diff", :bright))} #{@version}

    Compares distributed and local env files.

    Files given as #{to_string(colored("--dist", :bright))} will be read and merged to determine the required
    environment variable names.

    Files given as #{to_string(colored("--file", :bright))} will be read and merged to determine the local
    environment configuration.

    The tool will then print missing and extra local variables.

    Usage
    mix env.diff --dist .env.dist --file .env --file .env.test

    Options
    #{to_string(colored("--dist", :bright))}      Add a dist file
    #{to_string(colored("--file", :bright))}      Add an env file to check
    #{to_string(colored("--fix", :bright))}       Run the interactive fixer to sync files

    Note that the fixer will not do any modification to your files until you
    choose to do so.
    """
    |> IO.puts()
  end

  defp do_run(ctx),
    do: do_run(ctx, true)

  defp do_run(%{fix: fix?} = ctx, show_fix_opt?) do
    sources = build_sources(ctx)
    diff = diff(sources)

    case Distopy.display_diff(sources, diff) do
      :ok ->
        :ok

      :error when fix? ->
        Distopy.run_fixer(sources, diff)
        info("Fixer finished, checking new values")
        do_run(%{ctx | fix: false}, false)

      :error when show_fix_opt? ->
        IO.puts(:stderr, "\nrun with --fix to run the interactive fixer")
        :error

      :error ->
        :error
    end
    |> case do
      :ok -> :ok
      :error -> abort()
    end
  end

  defp build_sources(%{dist_files: dist, env_files: env} = _ctx) do
    dist =
      case Enum.map(dist, &EnvFile.new(&1)) do
        [single] -> single
        list -> list |> Enum.into(%{}, &{&1.path, &1}) |> SourceGroup.new()
      end

    env =
      case Enum.map(env, &EnvFile.new(&1, hide_values: true)) do
        [single] -> single
        list -> list |> Enum.into(%{}, &{&1.path, &1}) |> SourceGroup.new()
      end

    %{dist_source: dist, env_source: env}
  end

  defp diff(%{dist_source: dist, env_source: env}) do
    %{missing: _, extra: _} = Distopy.diff_keys(dist, env)
  end
end
