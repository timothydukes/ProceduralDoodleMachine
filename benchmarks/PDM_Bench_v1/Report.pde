// CSV + summary output. Both files land in this sketch folder so they can
// be committed straight into benchmarks/ in the repo.

PrintWriter csv;
StringList summaryLines = new StringList();

void openCsv() {
  String name = "pdm_bench_" + machineLabel + "_" + rendererLabel + "_" + stamp + ".csv";
  csv = createWriter(sketchPath(name));
  csv.println("test,resolution,load_name,load,fps,result");
  csv.flush();
}

void csvRow(String test, String res, String loadName, int load, float fps, String result) {
  csv.println(test + "," + res + "," + loadName + "," + load + "," + nf(fps, 0, 2) + "," + result);
  csv.flush();
}

void closeCsv() {
  if (csv != null) { csv.flush(); csv.close(); }
}

void note(String line) {
  println(line);
  summaryLines.append(line);
}

void saveSummary() {
  String name = "pdm_summary_" + machineLabel + "_" + rendererLabel + "_" + stamp + ".txt";
  saveStrings(sketchPath(name), summaryLines.array());
}
