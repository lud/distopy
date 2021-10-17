defmodule Distopy do
  alias Distopy.Source
  alias Distopy.Presenter.CLI

  def diff_keys(dist_source, env_source) do
    dist_keys = Source.list_keys(dist_source)
    env_keys = Source.list_keys(env_source)
    missing = dist_keys -- env_keys
    extra = env_keys -- dist_keys

    %{missing: missing, extra: extra}
  end

  def diff_and_output(dist, env, opts \\ []) do
    opts = Keyword.put_new(opts, :show_fix_opt, true)
    diff_and_output(dist, env, diff_keys(dist, env), opts)
  end

  def diff_and_output(dist, env, %{missing: missing, extra: extra} = _diff, opts) do
    valid? = length(missing) == 0 and length(extra) == 0

    if length(missing) > 0, do: CLI.print_missing(missing, dist, env)
    if length(extra) > 0, do: CLI.print_extra(extra, dist, env)

    cond do
      valid? ->
        CLI.print_sync_ok(dist, env)
        :ok

      !!opts[:show_fix_opt] ->
        Distopy.Shell.warn("\nrun with --fix to run the interactive fixer")
        :error

      true ->
        :error
    end
  end

  def run_fixer(
        dist,
        env,
        %{missing: missing, extra: extra} = _diff
      ) do
    if length(missing) > 0, do: CLI.fix_missing(missing, dist, env)
    if length(extra) > 0, do: CLI.fix_extra(extra, dist, env)
    :ok
  end

  def diff_and_fix(dist, env) do
    diff = diff_keys(dist, env)

    with :error <- diff_and_output(dist, env, diff, show_fix_opt: false),
         :ok <- run_fixer(dist, env, diff) do
      diff_and_output(dist, env, diff, show_fix_opt: false)
    end
  end
end
