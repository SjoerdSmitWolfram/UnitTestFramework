query = Query[{
	"TestReportObject" -> (#["ReportSucceeded"] &),
	"Summary" -> (Normal @ #[RowKey["ExampleUnitTests.wlt"]] &),
	"TestConfiguration" -> Keys
}];

exampleConfigFile = FileNameJoin[{
	ParentDirectory @ $TestConfig["TestDirectory"],
	"Examples", "Tests", "TestConfig.m"
}];

TestCreate[
	query[RunTests[exampleConfigFile]]
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
	TestID->"Test-70036076-747b-484a-b804-abfbaa36778f"
]
