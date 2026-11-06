# Input contract

The top-level JSON object has integer `schema_version: 1`, a `building_id`, a `label_scope` (`floor` or `building`), `floors`, `stacks`, `expected_cells` and `units` arrays.

Each floor and stack has an exact `id` and a display `label`. IDs are unique within their axis. Display order is the array order: `G`, `M`, `13A`, basement and nonnumeric labels need no numeric conversion. Text is preserved as valid UTF-8; there is no case folding, trimming, transliteration or Unicode normalization. Empty strings, outer whitespace and values over256 UTF-8 bytes are rejected.

Each planned position explicitly names a known `floor` and `stack`. It may occur only once. A displayed Cartesian-grid position omitted from `expected_cells` is **not planned**, rather than a missing apartment.

Each unit row has string fields `id`, `floor`, `stack`, `label`. Malformed required unit fields produce a row-level issue; malformed plan metadata rejects the whole input. Unrecognised source fields are ignored and are not copied to reports.

Limits: 10MB JSON text, 1..200 entries per axis, at most5000 displayed cells, at most5000 expected positions, at most100000 source unit rows. These bounds avoid accidental report explosions. There is no inference from price, status, area, title or optional private notes.

Unknown floor/stack references remain review findings. Label uniqueness uses the explicitly chosen scope: labels can repeat across different floors when `label_scope` is `floor`. Unit IDs must remain unique across the entire supplied building, even if a duplicate row also references an unknown floor.
