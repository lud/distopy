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

  def display_diff(
        %{dist_source: dist, env_source: env} = _sources,
        %{missing: missing, extra: extra} = _diff
      ) do
    valid? = length(missing) == 0 and length(extra) == 0

    if length(missing) > 0, do: CLI.print_missing(missing, dist, env)
    if length(extra) > 0, do: CLI.print_extra(extra, dist, env)

    if valid? do
      CLI.print_sync_ok(dist, env)
      :ok
    else
      :error
    end
  end

  def run_fixer(
        %{dist_source: dist, env_source: env} = _sources,
        %{missing: missing, extra: extra} = _diff
      ) do
    if length(missing) > 0, do: CLI.fix_missing(missing, dist, env)
    if length(extra) > 0, do: CLI.fix_extra(extra, dist, env)
  end
end
