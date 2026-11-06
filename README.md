# Property Unit Matrix Audit

A dependency-free D library and CLI for checking an **explicitly declared** building floor/stack matrix against supplied unit rows.

The tool answers practical editorial questions: which declared positions are empty, which contain conflicting rows, which unit identifiers repeat, and which labels collide within a declared floor or building scope. It preserves nonnumeric floor labels, intentional gaps and the supplied display order.

Developed by [NovAsia Estate](https://novasia.estate/). Source, examples, tests and method are public under MIT. The example building and units are entirely invented.

## What this is for

An agency receives several revisions of a developer's unit spreadsheet. Ground and technical floors should not be inferred as apartments. A replaced row can accidentally coexist with its predecessor. Identical unit IDs can appear on different floors. Inspecting the plan as a grid, alongside the exact rejected source rows, is often easier than reading a generic validation log.

This tool audits supplied structure. It does **not** establish sale availability, reservations, ownership, legal numbering or building compliance. Missing positions refer only to the author's declared `expected_cells`, never to an inferred full building.

## Run the example

Install a current D compiler and DUB, then:

```sh
dub test --config=unittest
dub run --config=cli -- examples/sample.json --html out/report.html --json out/report.json
```

The supplied example intentionally exits **1**, with 4 expected positions: 2 occupied, 1 missing, 1 requiring review. Three source rows have issues: two rows occupy the same position, and one references an undeclared floor. Ground-floor positions are grey `not_planned` cells.

Open `out/report.html` locally. The JSON report contains the same statuses and one-based source row references. No network requests or credentials are needed to run the audit.

## Use as a library

Add `property-unit-matrix` as a DUB dependency after the registry release is available:

```d
import propertymatrix;
import std.file : readText;

auto plan = parsePlan(readText("plan.json"));
auto result = audit(plan);
assert(result.expectedCells == 4);
auto html = htmlReport(result);
auto json = jsonReport(result);
```

The library configuration excludes the CLI entry point. All runtime functionality uses D's standard library.

## Input and output

- [Input contract](docs/input.md): schema, exact IDs, label scope and limits.
- [Review method](docs/method.md): issue precedence and matrix semantics.
- [Integration](docs/integration.md): command exit codes, exports and privacy.
- [Synthetic input](examples/sample.json): a complete reproducible example.
- [Behavioral checks](tests/behavior.d): conflicts, intentional gaps, malformed inputs, Unicode, escaping and independent results.

## Limits

One input describes one building. A floor/stack position represents at most one unit row in this model. Duplexes, merged units and multi-position units need an explicit upstream modelling decision. There is no geometric floorplan inference, fuzzy ID repair or automatic spreadsheet column mapping. Labels and IDs can be sensitive; the report remains a local file until someone chooses to share it.
