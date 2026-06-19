query = Query[{
	"TestReportObject" -> (#["ReportSucceeded"] &),
	"Summary" -> (Normal @ #[RowKey["ExampleUnitTests.wlt"]] &),
	"TestConfiguration" -> Keys/*Sort
}];

TestCreate[
	query[RunTests[$TestConfig["ExampleConfigFile"]]]
	,
	Association[
		"TestReportObject" -> True, 
		"Summary" -> Association["FileName" -> "ExampleUnitTests.wlt",  "Success" -> 8, "Failure" -> 0, "PerformanceFailure" -> 0,
			"Fixed" -> 1, "Implemented" -> 2, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 1],
		"TestConfiguration" -> {
			"AbortOnFail",  "OnTestResult", "PacletContexts", "PacletDirectory", "PacletInitialization", "RandomSeeding", "ReportType", 
			"SkipGeneratedTests", "SkipUnimplemented", "TestCategorizationFunction", "TestDirectory", "TestEvaluationFunction", "TestFileContext", 
			"TestFiles", "TestReportOptions"
		}
	]
	,
	TestID->"Test-70036076-747b-484a-b804-abfbaa36778f"
]
