Clear[query, exampleConfigFile];

query[obj_?AssociationQ] := Query[{
	"TestReportObject" -> (#["ReportSucceeded"] &),
	"Summary" -> (Normal @ #[RowKey["ExampleUnitTests.wlt"]] &),
	"TestConfiguration" -> Keys
}] @ obj;

query[expr_] := expr;


exampleConfigFile = FileNameJoin[{
	ParentDirectory @ $TestConfig["TestDirectory"],
	"Examples", "Tests", "TestConfig.m"
}];

TestCreate[
	query[
		RunTests[exampleConfigFile]
	]
	,
	Association[
		"TestReportObject" -> True, 
		"Summary" -> Association["FileName" -> "ExampleUnitTests.wlt",  "Success" -> 8, "Failure" -> 0, "PerformanceFailure" -> 0,
			"Fixed" -> 1, "Implemented" -> 2, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 1],
		"TestConfiguration" -> {
			"AbortOnFail",  "OnTestResult", "PacletContexts", "PacletDirectory", "PacletInitialization", "PacletObject", "RandomSeeding", "ReportType", 
			"SkipGeneratedTests", "SkipUnimplemented", "TestCategorizationFunction", "TestConfigFile", "TestDirectory", "TestEvaluationFunction",
			"TestFileContext",  "TestFiles", "TestReportOptions"
		}
	]
	,
	TestID->"TestReport-1"
]

(* Test that the unit tests will work with the default settings by just pointing RunTests at the test directory *)
TestCreate[
	query[RunTests[None, "TestDirectory" -> DirectoryName @ exampleConfigFile]]
	,
	Association[
		"TestReportObject" -> True, 
		"Summary" -> Association["FileName" -> "ExampleUnitTests.wlt",  "Success" -> 8, "Failure" -> 0, "PerformanceFailure" -> 0,
			"Fixed" -> 1, "Implemented" -> 2, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 1],
		"TestConfiguration" -> {
			"AbortOnFail", "OnTestResult", "PacletContexts", "PacletDirectory", "PacletInitialization", "PacletObject", 
			"RandomSeeding", "ReportType", "SkipGeneratedTests", "SkipUnimplemented", "TestCategorizationFunction", "TestConfigFile", 
			"TestDirectory", "TestEvaluationFunction", "TestFileContext", "TestFiles", "TestReportOptions"
		}
	]
	,
	TestID->"TestReport-2"
]
