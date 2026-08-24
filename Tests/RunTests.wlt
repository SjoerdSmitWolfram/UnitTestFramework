Clear[query, exampleConfigFile];

query[obj_?AssociationQ] := Query[{
	"TestReportObject" -> (#["ReportSucceeded"] &),
	"Summary" -> Normal /* Most,
	"GroupedResults" -> Function[AssociationQ[#] && AllTrue[#, MatchQ[_TestReportObject]]],
	"TestConfiguration" -> Keys /* Sort,
	"TestFileContexts" -> AssociationQ,
	"TestTimings" -> AssociationQ,
	"TestMetaData" -> AssociationQ
}] @ KeySort[obj];

query[expr_] := expr;

$defaultExpectedResults[rules___] := KeySort @ Association[
	"ReportSucceeded" -> True,
	"TestReportObject" -> True,
	"Summary" -> {
		Association[
			"FileName" -> "ExampleUnitTests.wlt",  "Success" -> 8, "Failure" -> 0, "PerformanceFailure" -> 0,
			"Fixed" -> 1, "Implemented" -> 2, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 1
		]
	},
	"GroupedResults" -> True,
	"TestConfiguration" -> expectedConfigKeys,
	"$TestSuiteAbortedQ" -> False,
	"TestFilesWithFailures" -> {},
	"TestFileContexts" -> True,
	"TestTimings" -> True,
	"TestMetaData" -> True,
	rules
]

exampleConfigFile = FileNameJoin[{
	ParentDirectory @ $TestConfig["TestDirectory"],
	"Examples", "Tests", "TestConfig.m"
}];

exampleTestFile = FileNameJoin[{
	ParentDirectory @ $TestConfig["TestDirectory"],
	"Examples", "Tests", "ExampleUnitTests.wlt"
}];

expectedConfigKeys = Sort @ {
	"AbortOnFail", "LocalDependencies", "IgnoreLocalConfig", "LocalConfigFile", "LocalDependenciesLoaded", 
	"LocalDependenciesRoot", "OnTestResult", "PacletContextAliases", "PacletContexts", "PacletDirectory", "PacletInitialization", "PacletObject", 
	"RandomSeeding", "ReportType", "RunFirstFiles", "SkipTags", "TestCategorizationFunction", "TestConfigFile", "TestDirectory", 
	"TestEvaluationFunction", "TestFileContext", "TestFilePattern", "TestFiles", "TestReportOptions", "TestSections"
}

TestCreate[
	query[
		RunTests[exampleConfigFile]
	]
	,
	$defaultExpectedResults[
		"Summary" -> {
			Association[
				"FileName" -> "ExampleUnitTests.wlt",  "Success" -> 8, "Failure" -> 0, "PerformanceFailure" -> 0,
				"Fixed" -> 1, "Implemented" -> 2, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 1
			]
		}
	]
	,
	TestID->"TestReport-1"
]

(* Test that the unit tests will work with the default settings by just pointing RunTests at the test directory *)
TestCreate[
	query[RunTests[None, "TestDirectory" -> DirectoryName @ exampleConfigFile]]
	,
	$defaultExpectedResults[
		"Summary" -> {
			Association[
				"FileName" -> "ExampleUnitTests.wlt",  "Success" -> 8, "Failure" -> 0, "PerformanceFailure" -> 0,
				"Fixed" -> 1, "Implemented" -> 2, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 1
			]
		}
	]
	,
	TestID->"TestReport-2"
]

TestCreate[
	RunTests[exampleConfigFile, "SkipTags" ->"NotImplemented"] // query
	,
	$defaultExpectedResults[
		"Summary" -> {
			Association[
				"FileName" -> "ExampleUnitTests.wlt",  "Success" -> 8, "Failure" -> 0, "PerformanceFailure" -> 0,
				"Fixed" -> 1, "Implemented" -> 0, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 3
			]
		}
	]
	,
	TestID->"TestReport-3"
]

TestCreate[
	RunTests[exampleConfigFile, "SkipTags" ->{"NotImplemented", "GeneratedTest"}]//query
	,
	$defaultExpectedResults[
		"Summary" -> {
			Association[
				"FileName" -> "ExampleUnitTests.wlt",  "Success" -> 7, "Failure" -> 0, "PerformanceFailure" -> 0,
				"Fixed" -> 1, "Implemented" -> 0, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 4
			]
		}
	]
	,
	TestID->"TestReport-4"
]

(* Test that calling a test file directly works *)
TestCreate[
	RunTests[exampleTestFile] // query
	,
	$defaultExpectedResults[
		"Summary" -> {
			Association["FileName" -> "ExampleUnitTests.wlt",  "Success" -> 8, "Failure" -> 0, "PerformanceFailure" -> 0, "Fixed" -> 1,
				"Implemented" -> 2, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 1
			]
		}
	]
	,
	TestID->"TestReport-5"
]

TestCreate[
	RunTests[exampleConfigFile, "TestSections" -> _String?(StringEndsQ["s"])] // query
	,
	$defaultExpectedResults[
		"Summary" -> {
			Association["FileName" -> "ExampleUnitTests.wlt",  "Success" -> 6, "Failure" -> 0, "PerformanceFailure" -> 0, "Fixed" -> 1,
				"Implemented" -> 0, "KnownIssue" -> 2, "NotImplemented" -> 0, "Skipped" -> 5
			]
		}
	]
	,
	TestID->"TestReport-5"
]
