module propertymatrix.audit;
import propertymatrix.model;
import std.string : strip;
import std.utf : validate;

struct Issue { size_t row; string code; string message; }
struct CellResult {
    string floor;
    string stack;
    string status;
    size_t[] rows;
    string[] labels;
}
struct Result {
    string buildingId;
    string labelScope;
    Axis[] floors;
    Axis[] stacks;
    CellResult[] cells;
    Issue[] issues;
    size_t acceptedRows;
    size_t missingCells;
    size_t reviewCells;
    size_t occupiedCells;
    size_t expectedCells;
    size_t totalRows;
}

/** Audit the entire declared matrix. Inputs are read only and copied into the result. */
Result audit(const Plan plan) {
    validatePlan(plan);
    Result result;
    result.buildingId=plan.buildingId; result.labelScope=plan.labelScope;
    foreach (x; plan.floors) result.floors ~= Axis(x.id,x.label);
    foreach (x; plan.stacks) result.stacks ~= Axis(x.id,x.label);
    result.expectedCells=plan.expected.length; result.totalRows=plan.units.length;
    bool[string] floorIds, stackIds, expected;
    foreach(x;plan.floors) floorIds[x.id]=true;
    foreach(x;plan.stacks) stackIds[x.id]=true;
    foreach(x;plan.expected) expected[positionKey(x.floor,x.stack)]=true;
    size_t[string] idCounts, labelCounts;
    size_t[][string] positions;
    bool[] validRows=new bool[plan.units.length];
    foreach(i,u;plan.units) {
        foreach (field; [u.id,u.floor,u.stack,u.label]) validate(field);
        if(u.id.length) ++idCounts[u.id];
        auto k=positionKey(u.floor,u.stack);
        if((u.floor in floorIds) && (u.stack in stackIds) && (k in expected)) positions[k] ~= i;
        auto valid = !u.inputError.length;
        foreach(field;[u.id,u.floor,u.stack,u.label])
            if(!field.length || field.length>256 || field!=strip(field)) valid=false;
        validRows[i]=valid;
        if(valid && (u.floor in floorIds) && (u.stack in stackIds) && (k in expected))
            ++labelCounts[positionKey(plan.labelScope=="floor"?u.floor:"",u.label)];
    }
    bool[] flagged=new bool[plan.units.length];
    foreach(i,u;plan.units) {
        string code, message;
        auto k=positionKey(u.floor,u.stack);
        if(!validRows[i]) {code="invalid_row";message=u.inputError.length?u.inputError:"Invalid required text field";}
        else if(idCounts[u.id]>1) {code="duplicate_id";message="Every occurrence of this unit ID requires review";}
        else if(!(u.floor in floorIds)) {code="unknown_floor";message="Floor is not declared in the plan";}
        else if(!(u.stack in stackIds)) {code="unknown_stack";message="Stack is not declared in the plan";}
        else if(!(k in expected)) {code="outside_plan";message="Position is not declared in expected_cells";}
        else if(positions[k].length>1) {code="multiple_rows_in_cell";message="Several rows occupy one planned position";}
        else if(labelCounts[positionKey(plan.labelScope=="floor"?u.floor:"",u.label)]>1) {
            code="duplicate_label";message="Display label repeats within the declared label scope";
        }
        if(code.length) {flagged[i]=true;result.issues ~= Issue(i+1,code,message);}
        else ++result.acceptedRows;
    }
    foreach(floor;plan.floors) foreach(stack;plan.stacks) {
        auto k=positionKey(floor.id,stack.id);
        CellResult cell;cell.floor=floor.id;cell.stack=stack.id;
        if(!(k in expected)) cell.status="not_planned";
        else {
            if(auto rows=k in positions) {
                foreach(row;*rows) {cell.rows ~= row+1; cell.labels ~= plan.units[row].label;}
                bool clean=(*rows).length==1 && !flagged[(*rows)[0]];
                cell.status=clean?"occupied":"review";
                if(clean) ++result.occupiedCells; else ++result.reviewCells;
            } else {cell.status="missing"; ++result.missingCells;}
        }
        result.cells ~= cell;
    }
    return result;
}
