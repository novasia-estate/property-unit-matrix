module propertymatrix.report;
import propertymatrix.audit;
import std.json;
import std.conv : to;
import std.array : appender;
import std.string : replace;

/** Escape text, including caller-supplied axis labels and IDs. */
string escapeHtml(string s) {
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
}

/** Explicit allowlist of report fields; unknown source properties are not exported. */
string jsonReport(const Result r) {
    JSONValue root=JSONValue(JSONValue[string].init);
    root["schema_version"]=JSONValue(1);
    root["building_id"]=JSONValue(r.buildingId);root["label_scope"]=JSONValue(r.labelScope);
    JSONValue stats=JSONValue(JSONValue[string].init);
    stats["total_rows"]=JSONValue(cast(ulong)r.totalRows);stats["accepted_rows"]=JSONValue(cast(ulong)r.acceptedRows);
    stats["expected_cells"]=JSONValue(cast(ulong)r.expectedCells);stats["occupied_cells"]=JSONValue(cast(ulong)r.occupiedCells);
    stats["missing_cells"]=JSONValue(cast(ulong)r.missingCells);stats["review_cells"]=JSONValue(cast(ulong)r.reviewCells);
    root["summary"]=stats;
    JSONValue[] cells, issues;
    foreach(c;r.cells) {
        JSONValue x=JSONValue(JSONValue[string].init);
        x["floor"]=JSONValue(c.floor);x["stack"]=JSONValue(c.stack);x["status"]=JSONValue(c.status);
        JSONValue[] rows,labels;
        foreach(n;c.rows)rows~=JSONValue(cast(ulong)n);
        foreach(s;c.labels)labels~=JSONValue(s);
        x["rows"]=JSONValue(rows);x["labels"]=JSONValue(labels);cells~=x;
    }
    foreach(i;r.issues) {
        JSONValue x=JSONValue(JSONValue[string].init);
        x["row"]=JSONValue(cast(ulong)i.row);x["code"]=JSONValue(i.code);x["message"]=JSONValue(i.message);issues~=x;
    }
    root["cells"]=JSONValue(cells);root["issues"]=JSONValue(issues);
    return toJSON(root,true);
}

/** A local standalone HTML matrix, preserving declared display order and exact labels. */
string htmlReport(const Result r) {
    auto b=appender!string();
    b.put(`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Property Unit Matrix Audit</title><style>body{margin:0;background:#f2f5f8;color:#172d42;font:16px/1.5 system-ui}main{max-width:1180px;margin:auto;padding:28px}header{background:#172d42;color:white;padding:26px;border-radius:14px}.scroll{overflow:auto}table{border-collapse:collapse;background:white;width:100%;margin:20px 0}th,td{border:1px solid #d5dfe7;padding:12px;text-align:left;min-width:100px}.occupied{background:#dff3e8}.missing{background:#ffedcf}.review{background:#ffdfe0}.not_planned{background:#e9edf0;color:#677783}aside{padding:18px;background:white;border-left:4px solid #b57712}footer{margin-top:25px}small{display:block}code{font-size:13px}</style><main><header><p>DECLARED INVENTORY / STRUCTURAL AUDIT</p><h1>Property Unit Matrix Audit</h1><p>Building: `);
    b.put(escapeHtml(r.buildingId)); b.put(`</p></header><p>Expected positions: <b>`~to!string(r.expectedCells)~`</b>. Occupied: <b>`~to!string(r.occupiedCells)~`</b>. Missing: <b>`~to!string(r.missingCells)~`</b>. Review: <b>`~to!string(r.reviewCells)~`</b>.</p><aside>Only explicitly declared expected cells can be missing. Grey cells are not planned. A red review cell has conflicting or invalid supplied rows. This report does not establish availability, reservation status, title, legal numbering or architectural compliance.</aside><h2>Declared matrix</h2><p>Green: occupied. Amber: missing. Red: review. Grey: not planned. Floor and stack order follows the supplied plan.</p><div class="scroll"><table><thead><tr><th>Floor / stack</th>`);
    foreach(s;r.stacks)b.put("<th>"~escapeHtml(s.label)~"<small>"~escapeHtml(s.id)~"</small></th>");
    b.put("</tr></thead><tbody>");
    size_t cursor;
    foreach(f;r.floors) {
        b.put("<tr><th>"~escapeHtml(f.label)~"<small>"~escapeHtml(f.id)~"</small></th>");
        foreach(s;r.stacks) {
            auto c=r.cells[cursor++];
            b.put(`<td class="`~c.status~`"><b>`~escapeHtml(c.status)~"</b>");
            foreach(i,label;c.labels)b.put("<small>"~escapeHtml(label)~" · source row "~to!string(c.rows[i])~"</small>");
            b.put("</td>");
        }
        b.put("</tr>");
    }
    b.put("</tbody></table></div><h2>Unit row review</h2><p>Accepted rows: "~to!string(r.acceptedRows)~" of "~to!string(r.totalRows)~". One primary issue per rejected row; row numbers are one-based within the units array.</p><div class=\"scroll\"><table><thead><tr><th>Row</th><th>Code</th><th>Reason</th></tr></thead><tbody>");
    foreach(i;r.issues)b.put("<tr><td>"~to!string(i.row)~"</td><td><code>"~escapeHtml(i.code)~"</code></td><td>"~escapeHtml(i.message)~"</td></tr>");
    b.put(`</tbody></table></div><h2>Interpretation</h2><p>IDs use exact text with no case folding or inferred floor numbers. Label uniqueness scope: `~escapeHtml(r.labelScope)~`. Duplicate IDs include malformed/out-of-plan occurrences. Cells retain all rows placed in that declared position, including invalid rows, so a conflicting occupied position is shown for review rather than silently called missing.</p><footer>Developed by <a href="https://novasia.estate/">NovAsia Estate</a>. <a href="https://github.com/novasia-estate/property-unit-matrix">Source, method and examples</a>. Supplied labels may be sensitive; control access to local reports.</footer></main></html>`);
    return b.data;
}
