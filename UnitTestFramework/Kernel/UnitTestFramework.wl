(*

The basic file structure expected by the code in this file is:

root/
├── PacletDir/                  # Paclet directory
│   └── PacletInfo.wl
└── Tests/                      # Unit testing directory
    └── TestConfig.*              # Test configuration file for the project

Unit test files are expected to be of the .wlt type and should all be located in the Tests directory or any of its sub-directories. All tests should be defined using TestCreate. Do not use VerificationTest; this is an outdated way to define tests.

A typical example of how to use TagTest would be:

TestCreate[
	Total @ RandomReal[1, 10^6]
	,
	_?NumericQ,
	SameTest -> MatchQ
] // TagTest["PerformanceTest", ...]

note that TagTest["PerformanceTest"] is equivalent to TagTest["PerformanceTest" -> True]

The TestConfig file can be either a Wolfram file that defines the $TestConfig variable or any other kind of file that returns an association. If you use a Wolfram file, you can use it to further customize the test report functionality by defining your own test evaluator on top of the default one and/or your own test result categorization function.

Description of config keys in the TestConfig file:

- "AbortOnFail": If True, stop running additional tests after the first unexpected failure (i.e., failing tests excluding tests tagged as KnownIssue/NotImplemented). This is useful for debugging unexpected

- "OnTestResult": Callback function applied to each TestObject as soon as it is produced. Useful for logging, progress reporting, or custom side effects.

- "ReportType": Controls test breadth. Use "Full" for full suite behavior, including performance/full-report-only tests; use other values (for example,
	local runs) to skip those heavier tests.

- "SkipTags": Tags that should be skipped. Tests tagged "Skip" will always be skipped.

- "TestDirectory": Main directory of the test files. Defaults to the directory of the TestConfig file.

- "TestFiles": Which .wlt files to run. Use All to discover all tests under the Tests directory recursively using the "TestFilePattern" property, or provide an explicit list of file paths relative to "TestDirectory".

- "TestFilePattern": File pattern to use to detect test files to run. Only has any effect if "TestFiles" -> All is used. 

- "TestFileContext": Base $Context used while evaluating tests. Each test file gets a unique sub-context under this value to isolate helper symbols defined in the test file.

- "PacletDirectory": When set to Automatic, RunTests will attempt to find the paclet directory in the directory above Tests by locating the PacletInfo file. If the paclet directory is located somewhere else, use "PacletDirectory" to point RunTests to the right location. The directory will be passed into PacletDirectoryLoad so that Get can load it.

- "PacletContexts": Contexts to load/include on $ContextPath for tests. When set to Automatic, the test runner uses the last part in the path of the "PacletDirectory" property the paclet context as well as any contexts declared in the PacletInfo.wl file. If PacletContexts is a list of multiple strings, the first one should be the main context that can be used to load the paclet using Get. You can add additional contexts to be able to tests internal symbols in the paclet Note that the contexts {"UnitTestFramework`", "MUnit`", "System`"} will also be put on $ContextPath while running tests.

- "TestEvaluationFunction": Function that gets passed into TestReport[..., TestEvaluationFunction -> fun]. The value Automatic uses the function TestEvaluator defined in UnitTestFramework.wl. If you define your own test evaluation function, this function will replace the call to TestEvaluate inside of TestEvaluator. If you want to define your own TestEvaluationFunction (for example, to handle new tags not handled by TestEvaluator), do it in the Private context below.

- "RandomSeeding": Seed to use for running the tests

- "TestCategorizationFunction": Function that labels test results according to test outcome and test tags. If set to Automatic, UnitTestFramework`CategorizeTestResult will be used. 

- "TestReportOptions": Options to feed into TestReport

- "PacletInitialization": Can take the following forms:
	- Automatic: evaluates `Get[pacletContext]` as inferred from the "PacletContexts" property.
	- Function[...]: function to be applied to the fully resolved TestConfig association.
	- Hold[...]: Held expression that gets released.

Note that the properties {"TestCategorizationFunction", "PacletInitialization", "TestEvaluationFunction", "OnTestResult", "TestReportOptions"} can 
contain Wolfram code. When using a non-Wolfram config format, these properties can contain an InputForm string that will get converted with ToExpression.

*)

ClearAll @@ Names["UnitTestFramework`" ~~ ___];

BeginPackage["UnitTestFramework`"]

$TestConfig::usage = "$TestConfig is an Association that holds all relevant values for running the tests in a particular project. It's defined using the Tests/TestConfig.m file.";

$TestConfigDefaults::usage = "$TestConfigDefaults holds default values for keys that aren't specified in the TestConfig file or the 2nd argument of RuntTests."

$TestResults::usage = "$TestResults is a variable that holds the raw output of TestReport before post-processing the results";

$TestReport::usage = "$TestReport holds the filtered test report used for automated pass/fail evaluation.";

$GroupedResults::usage = "$GroupedResults is an association with TestObjects according to their categorization.";

TestEvaluator::usage = "TestEvaluator is the test evaluation function used inside TestReport when running tests with RunTests[$$]. It has special handling logic for tests tagged using TagTest.";

$TestSuiteAbortedQ::usage = "$TestSuiteAbortedQ is a boolean that gets set to False at the start of the report. When set to True in the middle of a report, all remaining tests will be skipped.";

$TestTags::usage = "$TestTags is an association with descriptions of the tags that can be used in TagTest."


GeneralUtilities`SetUsage[TagTest,
	"TagTest[tags$1, tag$2, $$][test$] attaches metadata tags to a test expression. See $TestTags for details about the tags that can be used.
TagTest[tag$ -> val$, $$][test$] sets a specific value for a specified tag. The default value for tags without explicit values is True."
];

GeneralUtilities`SetUsage[ToDecimalDigits,
	"ToDecimalDigits[expr$, n$] converts numbers in expr$ to a form with at most n$ digits after the decimal dot. This can help make numerical test results more reproducible."
];

GeneralUtilities`SetUsage[TestReportSummary,
	"TestReportSummary[report$] returns a tabular summary of test outcomes grouped by test file and category.
TestReportSummary[] returns the summary of the most recently executed test report."
];

GeneralUtilities`SetUsage[RunTests,
	"RunTests[file$] runs unit tests defined by the key-value data in config file file$. Returns an association with a TestReportObject and a test summary table.
RunTests[file$, rules$] overrides properties in the config file with other values.
RunTests[dir$, $$] uses dir$ as the test directory and automatically tries to find a TestConfig file in that directory. If there are multiple options, a ChoiceDialog will ask the user which one should be used. If no config file is found, a message is issued and the tests will be run using default settings.
RunTests[None, rules$] takes all configuration directly from rules$."
];

GeneralUtilities`SetUsage[PostTestCleanUp,
	"PostTestCleanUp[] removes the contexts created during the test run from $ContextPath and cleans up symbols defined in the test files."
];

GeneralUtilities`SetUsage[CategorizeTestResult,
	"CategorizeTestResult[testObject$] returns the display category for a test result object, such as \"Success\", \"Failure\", \"Skipped\", or the corresponding not-implemented/known-issue variants.

Possible categories are:
| 'Success' | test evaluated as expected |
| 'Failure' | test evaluated not as expected |
| 'KnownIssue' | test failed, but this was expected because of a bug |
| 'NotImplemented' | test failed because the feature hasn't been implemented yet |
| 'PerformanceFailure' | test failed because of time or memory constraint |
| 'Fixed' | a 'KnownIssue' test that now passes |
| 'Implemented' | a 'NotImplemented' test that now passes |
| 'Skipped' | test did not run |
"
];

GeneralUtilities`SetUsage[CombineReports,
	"CombineReports[res$1, res$2, $$] combines test results into a single TestReportObject. Each res$i can be a TestObject, TestReportObject or a list of such."
];

Begin["`Private`"]

$defaultTestContexts = {"UnitTestFramework`", "MUnit`", "System`"};

SetAttributes[initVar, HoldFirst];
initVar[var_, val_] := If[
	!ValueQ[var, Method -> "SymbolDefinitionsPresent"],
	var = val,
	var
];

initVar[$TestConfig, <||>];


Clear[ToDecimalDigits];
SetAttributes[ToDecimalDigits, Listable];

ToDecimalDigits[expr_] := ToDecimalDigits[expr, 4];
ToDecimalDigits[expr_?NumericQ, n_] := N[Round[N @ expr * 10^n] / 10^n];
ToDecimalDigits[expr_, n_] := ToDecimalDigits[#, n]& /@ expr


$TestTags = <|
	"Skip" -> "Do not run this test right now. Use \"Skip\" -> False to force a test to run regardless of other considerations.",
	"NotImplemented" -> "Skip this test - test is expected to fail because functionality hasn't been implemented.",
	"KnownIssue" -> "Run this test - currently expected to fail till the underlying issue gets fixed.",
	"PerformanceTest" -> "Test if an evaluation does not require excessive time/memory. Tests with a TimeConstraint or MemoryConstraint \
are automatically classified as \"PerformanceTest\"",
	"FullReportOnly" -> "Test that should be skipped when running quick local test suite.",
	"BreakPoint" -> "Stop the test suite at this test to reproduce the kernel state. Only to be used for development and debugging purposes.",
	"GeneratedTest" -> "Automatically generated test (e.g., by some other code you might have)."
|>;


TagTest[tags___] := Function[test, iTagTest[test, tags], HoldAllComplete];

SetAttributes[iTagTest, HoldAllComplete];
iTagTest[test_] := test;
iTagTest[test_, <||>] := test;
iTagTest[(h : TestCreate | VerificationTest)[args___, MetaInformation -> assoc_Association, rest___], tags_Association] := h[
	args,
	rest,
	MetaInformation -> Merge[{assoc, tags}, Last]
];
iTagTest[(h : TestCreate | VerificationTest)[args___], tags_Association] := h[
	args,
	MetaInformation -> tags
];
iTagTest[test_, tags___] := With[{assoc = toTagAssociation[tags]},
	iTagTest[test, assoc]
];

toTagAssociation[tags___] := Association[
	Replace[Flatten[{tags}], tag : Except[_Rule] :> (tag -> True), {1}]
]

skipTestQ[meta_, test_] /; BooleanQ[meta["Skip"]] := meta["Skip"];
skipTestQ[meta_, test_] := Or[
	AnyTrue[
		Keys[$TestConfig["SkipTags"]],
		TrueQ @ meta[#]&
	],
	And[
		(* Only do performance test in the full report *)
		$TestConfig["ReportType"] =!= "Full",
		Or[
			TrueQ[meta["PerformanceTest"]],
			TrueQ[meta["FullReportOnly"]],
			NumericQ[test["MemoryConstraint"]],
			NumericQ[test["TimeConstraint"]]
		]
	]
];

$TestSuiteAbortedQ = False;

TestEvaluator[t_TestObject] := TestEvaluator[t, t["MetaInformation"]];
TestEvaluator[test_TestObject, meta_] := Which[
	TrueQ @ meta["BreakPoint"],
		$TestSuiteAbortedQ = True;
		$TestConfig["OnTestResult"][test];
		test
	,
	TrueQ[$TestSuiteAbortedQ] || skipTestQ[meta, test],
		$TestConfig["OnTestResult"][test];
		test
	,
	True,
		With[{
			res = $TestConfig["TestEvaluationFunction"][test]
		},
			If[ And[
					TrueQ[$TestConfig["AbortOnFail"]],
					MatchQ[res["Outcome"], "Failure" | "MessageFailure"],
					! TrueQ @ meta["NotImplemented"],
					! TrueQ @ meta["KnownIssue"]
				],
				$TestSuiteAbortedQ = True
			];
			$TestConfig["OnTestResult"][res];
			res
		]
];

$categorizations = {"Success", "Failure", "PerformanceFailure", "Implemented", "Fixed", "KnownIssue", "NotImplemented", "Skipped"};

CategorizeTestResult[obj_TestObject] := iCategorizeTestResult[obj["Outcome"], obj["MetaInformation"], obj];

iCategorizeTestResult["NotEvaluated", __] := "Skipped";

iCategorizeTestResult["Success", meta_, obj_] := Which[
	TrueQ @ meta["KnownIssue"],
		"Fixed",
	TrueQ @ meta["NotImplemented"],
		"Implemented",
	True,
		"Success"
];

iCategorizeTestResult[outcome_, meta_, obj_] := Which[
	TrueQ @ meta["KnownIssue"],
		"KnownIssue",
	TrueQ @ meta["NotImplemented"],
		"NotImplemented",
	MatchQ[obj["FailureType"], "TimeConstrainedFailure" | "MemoryConstrainedFailure"],
		"PerformanceFailure",
	True,
		"Failure"
];

shortTestFileName[obj_TestObject] := Replace[
	obj["TestFileName"],
	s_String :> shortTestFileName[s]
];
shortTestFileName[s_String] := Replace[
	FileNameSplit[s],
	{
		(* The usual assumption is that all tests live in a "Tests" directory *)
		{Longest[___], "Tests", rest__} :> FileNameJoin[{rest}],
		list_List :> FileNameJoin[Reverse @ Take[Reverse[list], UpTo[3]]]
	}
];

colPriority[col_] := Lookup[
	{"FileName" -> 0, "Success" -> 1, "Failure" -> 2, "PerformanceFailure" -> 2, "Skipped" -> 10},
	col,
	9
]

sortTable[tab_?TabularQ] := ReverseSortBy[
	KeyTake[tab, SortBy[Sort @ ColumnKeys[tab], colPriority]],
	Key["Failure"]
];
sortTable[expr_] := expr;

TestReportSummary[report_] := TestReportSummary[report, Automatic]

TestReportSummary[tr_TestReportObject, fun_] := sortTable @ ToTabular[
	Map[ 
		Join[
			AssociationThread[$categorizations, 0],
			#
		]&,
		GroupBy[
			tr["Results"],
			{
				shortTestFileName,
				Replace[fun, Automatic -> Lookup[$TestConfig, "TestCategorizationFunction", CategorizeTestResult]]
			},
			Length
		]
	],
	"Dataset",
	<|"LevelNames" -> {"FileName"}|>
];

TestReportSummary[reports_List, fun_] := Join @@ Map[
	TestReportSummary[#, fun]&,
	reports
];

TestReportSummary[] := TestReportSummary[$TestResults];

CombineReports[reports___] := TestReport[Flatten[{reports}], TestEvaluationFunction -> Identity];


fileContext[filename_] := StringJoin[
	$TestConfig["TestFileContext"],
	StringRiffle[
		StringDelete[
			FileBaseName /@ FileNameSplit[shortTestFileName @ filename],
			Except[WordCharacter] | (StartOfString ~~ DigitCharacter..)
		],
		"`"
	],
	"`"
];


(* ================ Test config initialization Start ================ *)

$TestConfigDefaults = <|
	"AbortOnFail" -> False,
	"OnTestResult" -> Automatic,
	"ReportType" -> "Full",
	"TestFiles" -> All,
	"TestFilePattern" -> Automatic,
	"SkipTags" -> None,
	"TestFileContext" -> "UnitTestFramework`TestRun`",
	"PacletDirectory" -> Automatic,
	"PacletContexts" -> Automatic,
	"TestEvaluationFunction" -> Automatic,
	"RandomSeeding" -> 1234,
	"TestCategorizationFunction" -> Automatic,
	"TestReportOptions" -> {},
	"PacletInitialization" -> Automatic,
	"TestDirectory" -> Automatic
|>;

(* Properties that need to be defined as Wolfram code. *)
$wlCodeProperties = {"TestCategorizationFunction", "PacletInitialization", "TestEvaluationFunction", "OnTestResult", "TestReportOptions"}

getConfig[file_] := getConfig[file, ToLowerCase @ FileExtension[file]];
getConfig[file_, "m" | "wlt"] := Get[file];
getConfig[file_, ext_] := Module[{
	data = Association @ Switch[ext,
		"json",
			Import[file, "RawJSON"],
		_,
			Import[file]
	]
},
	If[ AssociationQ[data],
		(* Convert standard strings to Wolfram form *)
		data //= Map[
			Replace[{
					"Automatic" -> Automatic,
					"True" -> True,
					"False" -> False
			}]
		];
		(* Apply ToExpression to code-based properties *)
		data //= Query[
			Thread[
				$wlCodeProperties -> Replace[
					s_String :> ToExpression[s, InputForm]
				]
			]
		];
		DeleteCases[data, _Missing | _?FailureQ]
		,
		$Failed
	]
];


loadTestConfigAndInitialize[dir_?DirectoryQ, assoc_] := Module[{
	configFiles = FileNames["testconfig*", dir, IgnoreCase -> Automatic],
	selected,
	selectedFile
},
	selectedFile = Switch[ Length[configFiles],
		0,
			Message[RunTests::noConfig, dir];
			None
		,
		1,
			First[configFiles],
		2,
			selected = ChoiceDialog[
				StringRiffle[
					{
						{"Multiple test config files detected in test directory. Please choose which one to run:"},
						Splice @ Thread[{Range @ Length[configFiles], "-", Map[FileNameTake, configFiles]}]
					}
				] <> "\n",
				Range @ Length[configFiles]
			];
			If[ IntegerQ[selected],
				configFiles[[selected]],
				None
			]
	];
	loadTestConfigAndInitialize[
		selectedFile,
		Append[assoc, "TestDirectory" -> dir]
	]
];

loadTestConfigAndInitialize[f_, assoc_] := Module[{
	file = f,
	initialVals = Association[assoc],
	testAssoc = <||>,
	testFiles, namedFiles, filePattern,
	dir, res
},
	Enclose[
		ConfirmAssert[MatchQ[file, $configPatt]];
		file //= Replace[s_?FileExistsQ :> AbsoluteFileName[s]];
		If[ file =!= None,
			testAssoc = Confirm @ Block[{$TestConfig},
				res = Confirm @ getConfig[file];
				Which[
					(* If $TestConfig was defined in the file, use that definition *)
					AssociationQ[$TestConfig],
						$TestConfig,
					(* Otherwise use whatever was returned at the end of the file *)
					AssociationQ[res],
						res,
					True,
						$Failed
				]
			]
		];
		testAssoc = Merge[
			{
				initialVals,
				DeleteCases[testAssoc, _Missing | _?FailureQ],
				$TestConfigDefaults
			},
			First
		];
		
		If[ !DirectoryQ[testAssoc["TestDirectory"]],
			ConfirmAssert[file =!= None];
			testAssoc["TestDirectory"] = DirectoryName[file]
		];
		dir = testAssoc["TestDirectory"];

		$TestConfig = testAssoc;
		$TestConfig["TestConfigFile"] = file;

		$TestConfig["AbortOnFail"] //= TrueQ;
		$TestConfig["SkipTags"] //= Replace[
			{
				None -> <||>,
				s_String :> <|s -> True|>,
				l_List :> AssociationThread[l, True],
				a_?AssociationQ :> Select[a, TrueQ]
			}
		];
		ConfirmAssert[AssociationQ @ $TestConfig["SkipTags"]];
		
		$TestConfig["OnTestResult"] //= Replace[Automatic -> Function[Null]];
		$TestConfig["TestReportOptions"] //= Function[
			Replace[
				Association @ Flatten[{#}],
				{
					a_?AssociationQ :> Normal[a],
					_ :> {}
				}
			]
		];
		$TestConfig["TestEvaluationFunction"] //= Replace[Automatic -> TestEvaluate];
		$TestConfig["TestCategorizationFunction"] //= Replace[Automatic -> CategorizeTestResult];

		$TestConfig["TestFileContext"] //= Replace[Automatic -> "UnitTestFramework`TestRun`"];
		$TestConfig["TestFilePattern"] //= Replace[Automatic -> "*.wlt" | "*.mt"];

		If[ $TestConfig["PacletDirectory"] === Automatic,
			$TestConfig["PacletDirectory"] = Confirm @ pacletDirFind[ParentDirectory[dir]]
		];
		ConfirmAssert[pacletDirQ @ $TestConfig["PacletDirectory"]];
		$TestConfig["PacletObject"] = Import[FileNameJoin[{$TestConfig["PacletDirectory"], "PacletInfo.wl"}], "WL"];
		
		PacletDataRebuild[];
		PacletDirectoryLoad @ $TestConfig["PacletDirectory"];
		
		namedFiles = $TestConfig["TestFiles"];
		filePattern = $TestConfig["TestFilePattern"];

		testFiles = Switch[namedFiles,
			All,
				FileNames[filePattern, dir, Infinity]
			,
			_,
				Block[{$Path = {}},
					WithCleanup[
						SetDirectory[dir],
						ExpandFileName /@ Flatten[{namedFiles}],
						ResetDirectory[]
					]
				]
		];
		
		ConfirmAssert @ And[
			MatchQ[testFiles, {__}],
			AllTrue[testFiles, FileExistsQ]
		];
		$TestConfig["TestFiles"] = testFiles;

		If[ $TestConfig["PacletContexts"] === Automatic,
			$TestConfig["PacletContexts"] = DeleteDuplicates @ Flatten[{
				ConfirmMatch[pacletContexts[$TestConfig["PacletObject"]], {__String}]
			}]
		];
		$TestConfig["PacletContexts"] = ConfirmMatch[
			Flatten[{$TestConfig["PacletContexts"]}],
			{__String?(StringEndsQ["`"])}
		];
		Confirm @ Switch[$TestConfig["PacletInitialization"],
			Automatic,
				Get[First[$TestConfig["PacletContexts"]]]
			,
			_Function,
				$TestConfig["PacletInitialization"][$TestConfig],
			_,
				ReleaseHold[
					Replace[
						$TestConfig["PacletInitialization"],
						(h : Hold | HoldComplete)[args___] :> h[CompoundExpression[args]]
					]
				]
		];
		
		$TestConfig
		,
		Function[fail,
			$TestConfig = <||>;
			fail
		]
	]
]


(* ================ Test config initialization End ================ *)



pacletDirQ[dir_] := And[
	TrueQ @ DirectoryQ[dir],
	FileExistsQ @ FileNameJoin[dir, "PacletInfo.wl"]
]

pacletDirFind[findDir_] := Module[{
	pacletFile, pacletDir
},
	Enclose[
		pacletFile = FileNames["PacletInfo.wl", findDir, 2];
		ConfirmAssert[MatchQ[pacletFile, {_String}]];
		pacletFile = First[pacletFile];
		pacletDir = DirectoryName[pacletFile];
		pacletDir
		,
		Function[fail,
			Message[RunTests::pacletDir];
			fail
		]
	]
];

pacletContexts[obj_PacletObject] := With[{
	c1 = obj["Context"],
	c2 = Cases[
		obj["Extensions"],
		list : {"Kernel", __Rule} :> Lookup[Rest[list], "Context"]
	]
},
	DeleteDuplicates @ Select[Flatten[{c1, c2}], StringQ]
]

$configPatt = None | _?FileExistsQ;


(* ================ RunTests Start ================ *)

RunTests::pacletDir = "Paclet directory could not be located.";
RunTests::noConfig = "No config file found in directory `1`. Proceeding with default test suite."

RunTests[conf : $configPatt, a_Association?AssociationQ] := Block[{
	$TestConfig,
	$TestSuiteAbortedQ = False, (* initialize abort flag *)
	configFile = conf,
	assoc = a,
	i = 0,
	files,
	$fileContext, 
	init = OptionValue["PacletInitialization"],
	fullTestContextPath
},
	Enclose[
		Confirm @ loadTestConfigAndInitialize[configFile, assoc];
		files = $TestConfig["TestFiles"];
		fullTestContextPath = DeleteDuplicates @ Select[
			Flatten[{$defaultTestContexts, $TestConfig["PacletContexts"]}],
			StringQ
		];
		(* do not show progress in terminal sessions *)
		$ProgressReporting = TrueQ[$Notebooks];
		$TestResults = CombineReports @ Map[
			Function[
				If[ TrueQ[$TestSuiteAbortedQ]
					,
					(* skip the rest of the files if aborted *)
					Nothing
					,
					BlockRandom[
						$fileContext = fileContext[#];
						ClearAll[Evaluate[$fileContext <> "`*"]];
						Block[{
								$Context = $fileContext,
								$ContextPath = fullTestContextPath
							},
							TestReport[#,
								Sequence @@ $TestConfig["TestReportOptions"],
								TestEvaluationFunction -> TestEvaluator
							]
						],
						RandomSeeding -> $TestConfig["RandomSeeding"]
					]
				]
			],
			files
		];

		$GroupedResults = Join[
			Association @ Map[# -> {}&, $categorizations],
			GroupBy[
				$TestResults["Results"],
				$TestConfig["TestCategorizationFunction"]
			]
		];

		$TestReport = CombineReports @ Catenate @ KeyTake[
			$GroupedResults,
			(* Return only the outright failures and successes for the purposes of automated testing *)
			{"Success", "Fixed", "Implemented", "Failure", "PerformanceFailure"}
		];
		$GroupedResults //= Map[CombineReports];
		<|
			"ReportSucceeded" -> TrueQ[$TestReport["ReportSucceeded"]],
			"TestReportObject" -> $TestReport,
			"Summary" -> TestReportSummary[$TestResults],
			"GroupedResults" -> $GroupedResults,
			"TestConfiguration" -> KeySort @ $TestConfig,
			"$TestSuiteAbortedQ" -> $TestSuiteAbortedQ
		|>
	]
];
RunTests[conf : $configPatt, rest___] := With[{assoc = Association[rest]},
	RunTests[conf, assoc] /; MatchQ[assoc, _Association?AssociationQ]
];

RunTests[___] := $Failed;

(* ================ RunTests End ================ *)


PostTestCleanUp[] := Module[{
	syms = Names[$TestConfig["TestFileContext"] ~~ ___]
},
	ClearAll @@ syms;
	$ContextPath = DeleteCases[$ContextPath, _String?(StringStartsQ[$TestConfig["TestFileContext"]])]
];

initVar[$TestResults, CombineReports[]];
initVar[$TestReport, CombineReports[]];


End[]

EndPackage[]
