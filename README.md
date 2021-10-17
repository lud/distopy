# Distopy

**TODO: Add description**

## Installation


```elixir
def deps do
  [
    {:distopy, "~> 0.1.0"}
  ]
end
```

## Usage

The simplest way of using the tool is by using its mix task:

    mix env.diff --fix --file .env --file .env.dev --dist .env.dist

Multiple environment or dist files can be added and will then be treated as a
group. For instance, if the dist file defines the `MY_ENV` variable, and that
variable is only in `.env` but not in `.env.test`, passing both environment
files to the command will not display an error car the variable is found in the
given _group_.
