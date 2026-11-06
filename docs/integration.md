# Integration and privacy

The CLI accepts one plan JSON file. `--html` and `--json` are optional paths; parent directories are created when needed.

- Exit0: parsed plan with no missing/review cells or row issues.
- Exit1: a valid plan produced findings requiring review.
- Exit2: malformed input, plan-contract failure, invalid options or a file operation failed.

This is suitable for a CI gate: exit1 is an editorial finding, rather than a compiler crash. Preserve the original input separately; report generation never rewrites it.

The standalone HTML report escapes all caller-supplied text. It has no remote scripts, fonts, tracking or network requests. JSON exports only declared report fields. Unknown input properties such as contacts or private notes are not copied. Supplied labels themselves may still contain sensitive information: this is not an anonymisation tool.

The package exposes `parsePlan`, `validatePlan`, `audit`, `jsonReport`, `htmlReport`, and the public model structs through `import propertymatrix`. Audit results copy the axis arrays, so editing result labels does not mutate the caller's input plan.
