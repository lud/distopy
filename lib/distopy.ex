defmodule Distopy do
  alias Distopy.Source
  alias Distopy.Presenter.CLI

  @moduledoc """
  The main API for Distopy.

  #{"README.md" |> File.read!() |> String.split("<!-- mix_docs -->") |> Enum.at(1)}
  """

  def diff_keys(dist_source, env_source) do
    dist_keys = Source.list_keys(dist_source)
    env_keys = Source.list_keys(env_source)
    missing = dist_keys -- env_keys
    extra = env_keys -- dist_keys

    %{missing: Enum.sort(missing), extra: Enum.sort(extra)}
  end

  def diff_and_output(dist, env, opts \\ []) do
    opts = Keyword.put_new(opts, :show_fix_opt, true)
    diff_and_output(dist, env, diff_keys(dist, env), opts)
  end

  def diff_and_output(dist, env, %{missing: missing, extra: extra} = _diff, opts) do
    check_extra = Keyword.get(opts, :extra) != false
    check_missing = Keyword.get(opts, :missing) != false

    invalid? = (check_missing and length(missing) > 0) or (check_extra and length(extra) > 0)

    if check_missing and length(missing) > 0,
      do: CLI.print_missing(missing, dist, env)

    if check_extra and length(extra) > 0,
      do: CLI.print_extra(extra, dist, env)

    cond do
      not invalid? ->
        CLI.print_sync_ok(dist, env)
        :ok

      !!opts[:show_fix_opt] ->
        Distopy.Shell.warn("\nrun with --fix to run the interactive fixer")
        :error

      true ->
        :error
    end
  end

  def diff_and_fix(dist, env, opts \\ []) do
    diff = diff_keys(dist, env)

    opts = Keyword.put_new(opts, :show_fix_opt, false)

    with :error <- diff_and_output(dist, env, diff, opts),
         {:ok, {dist, env}} <- run_fixer(dist, env, diff) do
      diff_and_output(dist, env, diff_keys(dist, env), opts)
    end
  end

  def run_fixer(dist, env, %{missing: missing, extra: extra}) do
    {:ok, {dist, env}} = CLI.fix_missing(missing, dist, env)
    {:ok, {dist, env}} = CLI.fix_extra(extra, dist, env)
    {:ok, {dist, env}}
  end
end
