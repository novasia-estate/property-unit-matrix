module app;
import propertymatrix;
import std.stdio : writeln, stderr;
import std.file : readText, write, mkdirRecurse;
import std.path : dirName;
import std.getopt : getopt, defaultGetoptPrinter;
int main(string[] args) {
    string htmlPath, jsonPath;
    try {
        auto help=getopt(args,"html",&htmlPath,"json",&jsonPath);
        if(help.helpWanted || args.length!=2) {
            writeln("Usage: dub run --config=cli -- PLAN.json --html out/report.html --json out/report.json");
            return help.helpWanted?0:2;
        }
        auto result=audit(parsePlan(readText(args[1])));
        if(htmlPath.length){mkdirRecurse(dirName(htmlPath));write(htmlPath,htmlReport(result));}
        if(jsonPath.length){mkdirRecurse(dirName(jsonPath));write(jsonPath,jsonReport(result));}
        writeln("Expected: ",result.expectedCells,"; occupied: ",result.occupiedCells,
            "; missing: ",result.missingCells,"; review: ",result.reviewCells,
            "; row issues: ",result.issues.length);
        return result.missingCells || result.reviewCells || result.issues.length ? 1 : 0;
    } catch(Exception e) {stderr.writeln("Invalid input: ",e.msg); return 2;}
}
