module propertymatrix.model;
import std.json;
import std.exception : enforce;
import std.string : strip;
import std.utf : validate;

struct Axis { string id; string label; }
struct Position { string floor; string stack; }
struct Unit {
    string id;
    string floor;
    string stack;
    string label;
    string inputError;
}
struct Plan {
    string buildingId;
    string labelScope;
    Axis[] floors;
    Axis[] stacks;
    Position[] expected;
    Unit[] units;
}

/** Collision-free key for two exact UTF-8 identifiers. No Unicode folding. */
string positionKey(string floor, string stack) {
    import std.conv : to;
    return to!string(floor.length) ~ ":" ~ floor ~ to!string(stack.length) ~ ":" ~ stack;
}

private string requiredText(JSONValue obj, string key) {
    enforce(obj.type == JSONType.object, "Expected a JSON object");
    auto value = key in obj.object;
    enforce(value !is null && value.type == JSONType.string, "Expected string field: " ~ key);
    validate(value.str);
    enforce(value.str.length > 0 && value.str.length <= 256 && value.str == strip(value.str),
        "Text must be nonempty, <=256 UTF-8 bytes, with no outer whitespace: " ~ key);
    return value.str;
}
private JSONValue[] requiredArray(JSONValue obj, string key) {
    auto value = key in obj.object;
    enforce(value !is null && value.type == JSONType.array, "Expected array field: " ~ key);
    return value.array;
}

/** Parse an explicit plan. Invalid plan metadata fails atomically; malformed unit rows remain reviewable. */
Plan parsePlan(string text) {
    enforce(text.length <= 10_000_000, "Input exceeds 10 MB limit");
    auto obj = parseJSON(text);
    enforce(obj.type == JSONType.object, "Top-level JSON object required");
    auto schemaVersion = "schema_version" in obj.object;
    enforce(schemaVersion !is null && schemaVersion.type == JSONType.integer && schemaVersion.integer == 1,
        "schema_version must be integer 1");
    Plan p;
    p.buildingId = requiredText(obj, "building_id");
    p.labelScope = requiredText(obj, "label_scope");
    enforce(p.labelScope == "floor" || p.labelScope == "building", "label_scope must be floor or building");
    foreach (a; requiredArray(obj, "floors")) p.floors ~= Axis(requiredText(a, "id"), requiredText(a, "label"));
    foreach (a; requiredArray(obj, "stacks")) p.stacks ~= Axis(requiredText(a, "id"), requiredText(a, "label"));
    foreach (c; requiredArray(obj, "expected_cells")) p.expected ~= Position(requiredText(c, "floor"), requiredText(c, "stack"));
    auto rows = requiredArray(obj, "units");
    enforce(rows.length <= 100_000, "At most 100000 unit rows");
    foreach (row; rows) {
        Unit u;
        if (row.type != JSONType.object) {u.inputError = "Unit row must be an object"; p.units ~= u; continue;}
        foreach (key; ["id", "floor", "stack", "label"]) {
            auto value = key in row.object;
            string field;
            if (value is null || value.type != JSONType.string) {
                if (!u.inputError.length) u.inputError = "Missing or non-string field: " ~ key;
            } else {
                field = value.str;
                validate(field);
                if (!field.length || field.length > 256 || field != strip(field)) {
                    if (!u.inputError.length) u.inputError = "Empty, oversized or outer-whitespace field: " ~ key;
                }
            }
            switch(key) {
                case "id": u.id=field; break;
                case "floor": u.floor=field; break;
                case "stack": u.stack=field; break;
                case "label": u.label=field; break;
                default: assert(0);
            }
        }
        p.units ~= u;
    }
    validatePlan(p);
    return p;
}

/** Validate programmatic inputs too; axes and planned positions must be unambiguous. */
void validatePlan(const Plan p) {
    enforce(p.buildingId.length && p.buildingId.length <= 256, "Invalid building identifier");
    enforce(p.labelScope == "floor" || p.labelScope == "building", "Invalid label scope");
    enforce(p.floors.length > 0 && p.floors.length <= 200 && p.stacks.length > 0 && p.stacks.length <= 200,
        "Each axis requires 1..200 entries");
    enforce(p.floors.length * p.stacks.length <= 5_000, "At most 5000 displayed matrix cells");
    enforce(p.expected.length <= 5_000 && p.units.length <= 100_000, "Input collection limit exceeded");
    bool[string] floorIds, stackIds, cells;
    foreach (axis; p.floors) {
        validate(axis.id); validate(axis.label);
        enforce(axis.id.length && axis.label.length && axis.id.length <= 256 && axis.label.length <= 256,
            "Invalid floor ID/label");
        enforce(axis.id == strip(axis.id) && axis.label == strip(axis.label), "Outer whitespace in floor metadata");
        enforce(!(axis.id in floorIds), "Duplicate floor ID: " ~ axis.id); floorIds[axis.id]=true;
    }
    foreach (axis; p.stacks) {
        validate(axis.id); validate(axis.label);
        enforce(axis.id.length && axis.label.length && axis.id.length <= 256 && axis.label.length <= 256,
            "Invalid stack ID/label");
        enforce(axis.id == strip(axis.id) && axis.label == strip(axis.label), "Outer whitespace in stack metadata");
        enforce(!(axis.id in stackIds), "Duplicate stack ID: " ~ axis.id); stackIds[axis.id]=true;
    }
    foreach (cell; p.expected) {
        enforce(cell.floor in floorIds, "Unknown floor in expected_cells");
        enforce(cell.stack in stackIds, "Unknown stack in expected_cells");
        auto k=positionKey(cell.floor,cell.stack);
        enforce(!(k in cells), "Duplicate expected position"); cells[k]=true;
    }
}
