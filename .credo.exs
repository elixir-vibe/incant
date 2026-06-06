%{
  configs: [
    %{
      name: "default",
      plugins: [{ExSlop, []}],
      checks: [
        {Credo.Check.Design.AliasUsage, false},
        {Credo.Check.Readability.WithSingleClause, false},
        {Credo.Check.Refactor.Apply, false},
        {Credo.Check.Refactor.MapJoin, false},
        {Credo.Check.Refactor.Nesting, false},
        {Credo.Check.Refactor.RedundantWithClauseResult, false},
        {ExSlop.Check.Refactor.LengthComparison, false}
      ]
    }
  ]
}
