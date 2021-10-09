defmodule Distopy.Shell do
  # Process.sleep calls help to let stderr finish printing before possible
  # prints to stdio that would no show in order.

  def warn(io \\ :stderr, text) do
    IO.puts(io, colored(text, :yellow))
    Process.sleep(10)
  end

  def success(text) do
    IO.puts(:stderr, colored(text, :green))
    Process.sleep(10)
  end

  def error(text) do
    IO.puts(:stderr, colored(text, :red))
    Process.sleep(10)
  end

  def info(io \\ :stderr, text) do
    IO.puts(io, text)
    Process.sleep(10)
  end

  # when color in ~w(cyan blue magenta red yellow green)a
  def colored(text, color) do
    [apply(IO.ANSI, color, []), text, IO.ANSI.reset()]
  end

  def abort() do
    System.halt(1)
  end

  def abort(text) do
    error(text)
    abort()
  end
end
