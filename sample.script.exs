System.argv() |> IO.inspect(label: ~S[System.argv()])

Mix.Tasks.Env.Diff.run(System.argv(), [{~r/.+\.yaml/, :lol}])