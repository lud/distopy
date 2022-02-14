defmodule Mix.Tasks.Env.Diff do
  use Mix.Task
  import Distopy.Shell
  alias Distopy.Source.{EnvFile, SourceGroup}

  @version Distopy.MixProject.project() |> Keyword.fetch!(:version)

  @args_schema [
    dist: [:string, :keep],
    file: [:string, :keep],
    fix: :boolean,
    extra: :boolean,
    missing: :boolean,
    fail: :boolean
  ]

  @impl true
  def run(argv) do
    run(argv, [])
  end

  def run(argv, impls) do
    argv |> parse_args() |> do_run(impls)
  end

  defp parse_args(argv) do
    parsed = OptionParser.parse(argv, switches: @args_schema)

    case parsed do
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

  defp collect_opts(opts) do
    opts
    |> Enum.reduce(
      %{env_files: [], dist_files: [], fix: false, extra: true, missing: true, fail: true},
      fn
        {:file, file}, acc -> add_file(acc, :env_files, file)
        {:dist, file}, acc -> add_file(acc, :dist_files, file)
        {:fail, v}, acc when is_boolean(v) -> Map.put(acc, :fail, v)
        {:fix, v}, acc when is_boolean(v) -> Map.put(acc, :fix, v)
        {:extra, v}, acc when is_boolean(v) -> Map.put(acc, :extra, v)
        {:missing, v}, acc when is_boolean(v) -> Map.put(acc, :missing, v)
      end
    )
  end

  defp check_opts(%{env_files: env_files}) when length(env_files) < 1,
    do: abort("no file to check")

  defp check_opts(%{dist_files: dist}) when length(dist) < 1,
    do: abort("no dist file provided")

  defp check_opts(%{extra: false, missing: false}),
    do: abort("both --no-missing and --no-extra were provided")

  defp check_opts(fine_opts),
    do: fine_opts

  defp add_file(acc, key, file) do
    Map.update!(acc, key, &(&1 ++ [file]))
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
    #{usage_opt("--dist")} Add a dist file
    #{usage_opt("--file")} Add an env file to check
    #{usage_opt("--fix")} Run the interactive fixer to sync files
    #{usage_opt("--no-extra")} Ignore extra variables in env files
    #{usage_opt("--no-missing")} Ignore extra variables in dist files

    Note that the fixer will not do any modification to your files until you
    choose to do so.
    """
    |> IO.puts()
  end

  defp usage_opt(text) do
    colored(String.pad_trailing(text, 20), :bright)
  end

  defp do_run(%{fix: fix?, extra: extra, missing: missing, fail: fail?} = ctx, impls) do
    {dist, env} = build_sources(ctx, impls)

    if fix? do
      Distopy.diff_and_fix(dist, env, extra: extra, missing: missing)
    else
      Distopy.diff_and_output(dist, env, extra: extra, missing: missing)
    end
    |> case do
      :ok -> :ok
      :error -> if fail?, do: abort(), else: :ok
    end
  end

  defp build_sources(%{dist_files: dist_files, env_files: env_files} = _ctx, impls) do
    dist =
      case Enum.map(dist_files, &build_env_source(&1, impls, :dist)) do
        [single] -> single
        list -> list |> Enum.into(%{}, &{&1.path, &1}) |> SourceGroup.new()
      end

    env =
      case Enum.map(env_files, &build_env_source(&1, impls, :env)) do
        [single] -> single
        list -> list |> Enum.into(%{}, &{&1.path, &1}) |> SourceGroup.new()
      end

    {dist, env}
  end

  defp build_env_source(path, impls, kind) when is_binary(path) do
    builder =
      Enum.find(impls, fn {matcher, _impl} ->
        custom_file?(matcher, path)
        # if custom_file?(matcher, path) do
        #   IO.puts("using #{inspect(impl)} to load #{path}")
        #   true
        # else
        #   false
        # end
      end)

    case builder do
      {_, build} when is_function(build, 1) -> build.(path)
      {_, build} when is_atom(build) -> build.load_file(path)
      # IO.puts("using default .env parser to load #{path}")
      nil -> EnvFile.new(path, hide_values: kind != :dist, mutable: kind != :dist)
    end
  end

  defp custom_file?(matcher, path) do
    cond do
      Regex.regex?(matcher) -> Regex.match?(matcher, path)
      is_function(matcher, 1) -> matcher.(path)
      true -> false
    end
  end
end
