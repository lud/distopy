defmodule Distopy do
  alias Distopy.Source

  def diff_keys(dist_source, env_source) do
    dist_keys = Source.list_keys(dist_source)
    env_keys = Source.list_keys(env_source)
    missing = dist_keys -- env_keys
    extra = env_keys -- dist_keys

    %{missing: missing, extra: extra}
  end
end
