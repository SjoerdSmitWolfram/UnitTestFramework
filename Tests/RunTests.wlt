Clear[query, exampleConfigFile];

query[obj_?AssociationQ] := Query[{
	"TestReportObject" -> (#["ReportSucceeded"] &),
	"Summary" -> (Normal @ #[RowKey["ExampleUnitTests.wlt"]] &),
	"GroupedResults" -> Function[AssociationQ[#] && AllTrue[#, MatchQ[_TestReportObject]]],
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
		"ReportSucceeded" -> True,
		"TestReportObject" -> True, 
		"Summary" -> Association["FileName" -> "ExampleUnitTests.wlt",  "Success" -> 8, "Failure" -> 0, "PerformanceFailure" -> 0,
			"Fixed" -> 1, "Implemented" -> 2, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 1],
		"GroupedResults" -> True,
		"TestConfiguration" -> {
			"AbortOnFail",  "OnTestResult", "PacletContexts", "PacletDirectory", "PacletInitialization", "PacletObject", "RandomSeeding", "ReportType", 
			"SkipTags", "TestCategorizationFunction", "TestConfigFile", "TestDirectory", "TestEvaluationFunction",
			"TestFileContext", "TestFilePattern", "TestFiles", "TestReportOptions"
		},
		"$TestSuiteAbortedQ" -> False
	]
	,
	TestID->"TestReport-1"
]

(* Test that the unit tests will work with the default settings by just pointing RunTests at the test directory *)
TestCreate[
	query[RunTests[None, "TestDirectory" -> DirectoryName @ exampleConfigFile]]
	,
	Association[
		"ReportSucceeded" -> True,
		"TestReportObject" -> True, 
		"Summary" -> Association["FileName" -> "ExampleUnitTests.wlt",  "Success" -> 8, "Failure" -> 0, "PerformanceFailure" -> 0,
			"Fixed" -> 1, "Implemented" -> 2, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 1],
		"GroupedResults" -> True,
		"TestConfiguration" -> {
			"AbortOnFail", "OnTestResult", "PacletContexts", "PacletDirectory", "PacletInitialization", "PacletObject", 
			"RandomSeeding", "ReportType", "SkipTags", "TestCategorizationFunction", "TestConfigFile", 
			"TestDirectory", "TestEvaluationFunction", "TestFileContext", "TestFilePattern", "TestFiles", "TestReportOptions"
		},
		"$TestSuiteAbortedQ" -> False
	]
	,
	TestID->"TestReport-2"
]

TestCreate[
	RunTests[exampleConfigFile, "SkipTags" ->"NotImplemented"] // query
	,
	Association[
		"ReportSucceeded" -> True,
		"TestReportObject" -> True,
		"Summary" -> Association["FileName" -> "ExampleUnitTests.wlt",  "Success" -> 8, "Failure" -> 0,
			"PerformanceFailure" -> 0, "Fixed" -> 1, "Implemented" -> 0, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 3
		],
		"GroupedResults" -> True,
		"TestConfiguration" -> {
			"AbortOnFail",  "OnTestResult", "PacletContexts", "PacletDirectory", "PacletInitialization", "PacletObject", "RandomSeeding", "ReportType",
			"SkipTags", "TestCategorizationFunction", "TestConfigFile", "TestDirectory", "TestEvaluationFunction", "TestFileContext", "TestFilePattern",
			 "TestFiles", "TestReportOptions"
		},
		"$TestSuiteAbortedQ" -> False
	]
	,
	TestID->"TestReport-3"
]

TestCreate[
	RunTests[exampleConfigFile, "SkipTags" ->{"NotImplemented", "GeneratedTest"}]//query
	,
	Association[
		"ReportSucceeded" -> True,
		"TestReportObject" -> True,
		"Summary" -> Association["FileName" -> "ExampleUnitTests.wlt",  "Success" -> 7, "Failure" -> 0, "PerformanceFailure" -> 0, "Fixed" -> 1,
			 "Implemented" -> 0, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 4
		],
		"GroupedResults" -> True,
		"TestConfiguration" -> {
			"AbortOnFail",  "OnTestResult", "PacletContexts", "PacletDirectory", "PacletInitialization", "PacletObject", "RandomSeeding", "ReportType",
			"SkipTags", "TestCategorizationFunction", "TestConfigFile", "TestDirectory", "TestEvaluationFunction", "TestFileContext", "TestFilePattern", 
			"TestFiles", "TestReportOptions"
		},
		"$TestSuiteAbortedQ" -> False
	]
	,
	TestID->"TestReport-4"
]