module behavior;
import propertymatrix;
import std.exception : assertThrown;
import std.json;
import std.string : indexOf;

Plan sample() {
    return Plan("DEMO","floor",[Axis("1","One"),Axis("2","Two")],
        [Axis("A","East"),Axis("B","West")],
        [Position("1","A"),Position("1","B"),Position("2","A")],
        [Unit("u1","1","A","01"),Unit("u2","1","B","02"),Unit("u3","2","A","01")]);
}
unittest {auto r=audit(sample());assert(r.expectedCells==3 && r.occupiedCells==3 && r.acceptedRows==3);}
unittest {auto p=sample();p.units=p.units[0..2];auto r=audit(p);assert(r.missingCells==1 && r.reviewCells==0);}
unittest {auto r=audit(sample());assert(r.cells[3].status=="not_planned" && r.missingCells==0);}
unittest {auto p=sample();p.units~=Unit("u4","2","B","04");auto r=audit(p);assert(r.issues[0].code=="outside_plan" && r.acceptedRows==3);}
unittest {auto p=sample();p.units~=Unit("u4","9","A","04");auto r=audit(p);assert(r.issues[0].code=="unknown_floor");}
unittest {auto p=sample();p.units~=Unit("u4","1","Z","04");assert(audit(p).issues[0].code=="unknown_stack");}
unittest {auto p=sample();p.units[1].id="u1";auto r=audit(p);assert(r.issues.length==2 && r.reviewCells==2 && r.acceptedRows==1);}
unittest {auto p=sample();p.units~=Unit("u1","9","A","bad");auto r=audit(p);assert(r.issues[0].code=="duplicate_id" && r.reviewCells==1);}
unittest {auto p=sample();p.units~=Unit("u4","1","A","other");auto r=audit(p);assert(r.reviewCells==1 && r.issues.length==2);}
unittest {auto p=sample();p.units[1].label="01";auto r=audit(p);assert(r.issues.length==2 && r.reviewCells==2);}
unittest {auto p=sample();p.labelScope="building";auto r=audit(p);assert(r.issues.length==2 && r.reviewCells==2);}
unittest {auto p=sample();p.units[0].id="";auto r=audit(p);assert(r.issues[0].code=="invalid_row" && r.cells[0].status=="review" && r.missingCells==0);}
unittest {auto p=sample();p.units[0].id=" u1";assert(audit(p).issues[0].code=="invalid_row");}
unittest {auto p=sample();p.units=[];auto r=audit(p);assert(r.missingCells==3 && r.issues.length==0);}
unittest {auto p=sample();p.expected=[];auto r=audit(p);assert(r.missingCells==0 && r.acceptedRows==0 && r.issues.length==3);}
unittest {auto p=sample();p.floors~=Axis("1","Again");assertThrown(audit(p));}
unittest {auto p=sample();p.stacks~=Axis("A","Again");assertThrown(audit(p));}
unittest {auto p=sample();p.expected~=Position("1","A");assertThrown(audit(p));}
unittest {auto p=sample();p.expected~=Position("unknown","A");assertThrown(audit(p));}
unittest {auto p=sample();p.labelScope="automatic";assertThrown(audit(p));}
unittest {auto p=sample();p.floors=[];assertThrown(audit(p));}
unittest {assert(positionKey("a:","b")!=positionKey("a",":b"));assert(positionKey("11","2")!=positionKey("1","12"));}
unittest {auto p=sample();p.units[0].label="ห้องหนึ่ง";assert(audit(p).acceptedRows==3);}
unittest {auto p=sample();p.units[1].id="U1";assert(audit(p).acceptedRows==3);}
unittest {auto p=sample();auto r=audit(p);r.floors[0].label="changed";assert(p.floors[0].label=="One");}
unittest {auto p=sample();auto r=audit(p);auto j=parseJSON(jsonReport(r));assert(j["summary"]["occupied_cells"].integer==3);}
unittest {auto p=sample();p.buildingId="<script>alert(1)</script>";auto html=htmlReport(audit(p));assert(indexOf(html,"<script>")==-1 && indexOf(html,"&lt;script&gt;")>=0);}
unittest {auto p=sample();p.units[0].label="<img src=x>";auto html=htmlReport(audit(p));assert(indexOf(html,"<img src=x>")==-1 && indexOf(html,"&lt;img")>=0);}
unittest {assertThrown(parsePlan(`{"schema_version":2}`));}
unittest {auto p=sample();p.floors[0].label=" outer ";assertThrown(audit(p));}
