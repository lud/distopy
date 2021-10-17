# Distopy

## Installation


```elixir
def deps do
  [
    {:distopy, "~> 0.1.0"}
  ]
end
```

<!-- mix_docs -->

## Usage

The simplest way of using the tool is by using its mix task:

    mix env.diff --fix --file .env --file .env.dev --dist .env.dist

Multiple environment or dist files can be added and will then be treated as a
group. For instance, if the dist file defines the `MY_ENV` variable, and that
variable is only in `.env` but not in `.env.test`, passing both environment
files to the command will not display an error car the variable is found in the
given _group_.


## Usage with custom files

The `env.diff` mix task handles env files thanks to
[Dotenvy](https://hexdocs.pm/dotenvy/readme.html).

In order to use other types of sources (think CI configuration files like
`.gitlab-ci.yml`, env variables documentation in markdown etc), the
`Distopy.Source` protocol should be implemented for custom sources and handed to
`Distopy.diff_and_output/2` or `Distopy.diff_and_fix/2`.

For instance on an elixir project using Distopy one could simply call the mix
task with custom implementations for yaml files:

    build_sources = [{~r/.+\.yaml/, &MyYamlSource.new/1}]
    Mix.Tasks.Env.Diff.run(System.argv(), build_sources)

The `build_sources` is a list of `{match_file_path, build_source}` where
`match_file_path` is a regular expression or a function accepting the file path
and returning a boolean ; `build_source` is a function returning the
implementation of `Distopy.Source`.

Such a script would be called like the following:

    `mix run myscript.exs --file .env.yaml --dist .env.dist`

Outside of an Elixir project using Distopy, `Mix.install/1` can be used to
provide the functionality:

    Mix.install([:distopy])
    build_sources = [{~r/.+\.yaml/, &MyYamlSource.new/1}]
    Mix.Tasks.Env.Diff.run(System.argv(), build_sources)

To call the script just run:

    `elixir myscript.exs --file .env.yaml --dist .env.dist`

Happy coding!