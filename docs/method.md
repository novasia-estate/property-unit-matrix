# Review method

1. Validate the declared plan atomically: exact axis IDs, unique expected positions, known references and explicit limits.
2. Count all nonempty supplied unit IDs. A malformed or out-of-plan duplicate does not silently preserve another occurrence as an accepted identity.
3. Attach every row with a known, planned floor/stack tuple to that position, including malformed unit rows. This makes an invalid occupied position visible for review rather than falsely empty.
4. Assign one primary issue to each rejected row, in this order: invalid row, duplicate ID, unknown floor, unknown stack, position outside plan, multiple rows in cell, duplicate label within the chosen scope.
5. Render the complete declared floor/stack grid. Planned cells with no attached row are `missing`. A planned cell with exactly one accepted row is `occupied`. Any other attached planned cell is `review`. Undeclared positions are `not_planned`.

One primary issue per row means the row ledger is not an exhaustive list of every condition affecting that row. Cell findings still expose multiple occupants and review states. Row numbers are one-based positions within the `units` array, not spreadsheet physical line numbers.

The summary identity is `expected_cells = occupied_cells + missing_cells + review_cells`. `accepted_rows` counts rows with no primary issue. Out-of-plan and unknown-axis rows are visible in the ledger and do not create new planned cells. An empty `expected_cells` array is valid: it declares no expected units, so supplied rows are outside the plan.

This structural model makes no statement about current stock, event reservations, unit title, architecture or legal floor designations. Every planned position is author-supplied.
