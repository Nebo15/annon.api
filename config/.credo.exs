%{
  configs: [
    %{
      color: true,
      name: "default",
      files: %{
        included: ["lib/"]
      },
      checks: [
        {Credo.Check.Design.TagTODO, exit_status: 0},
        {Credo.Check.Design.AliasUsage, exit_status: 0},
        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 120},
        {Credo.Check.Readability.Specs, false},
        {Credo.Check.Refactor.FunctionArity, max_arity: 6},
      ]
    }
  ]
}
