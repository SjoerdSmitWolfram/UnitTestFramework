#!/usr/bin/env wolframscript

$testDir = DirectoryName @ $InputFileName;
$frameworkSource = FileNameJoin[{ParentDirectory @ $testDir, "UnitTestFramework", "Kernel", "UnitTestFramework.wl"}];

(* ── Argument parsing ──────────────────────────────────────────────────── *)

$args = Rest @ $ScriptCommandLine;

If[MemberQ[$args, "--usage"],
	Print["Usage: wolframscript -file Tests/run_tests.wls [--full] [--no-color] [--file=FILE[,FILE...]]"];
	Print[""];
	Print["  --full             Include performance tests (default: Local mode)"];
	Print["  --no-color         Disable terminal colors"];
	Print["  --dry-run          Do not run the tests"];
	Print["  --summary          Do not print the individual tests"];
	Print["  --file=FILE[,...]  Run only the specified file(s) or folder(s), relative to Tests/"];
	Print["                     Examples: --file=ModelFit.wlt"];
	Print["                               --file=ModelFit.wlt,Models/Peak.wlt"];
	Print["                               --file=Models"];
	Exit[0]
];

$fullQ  = MemberQ[$args, "--full" | "-f"];
$colorQ = ! MemberQ[$args, "--no-color"];
$dryQ   = MemberQ[$args, "--dry-run"];
$summaryQ   = MemberQ[$args, "--summary"];


(* ── File filter ────────────────────────────────────────────────────────── *)

resolveFileArg[arg_String] := Module[{rel = FileNameJoin[{$testDir, arg}]},
	Which[
		DirectoryQ[rel],  FileNames["*.wlt", rel, Infinity],
		FileExistsQ[rel], {rel},
		DirectoryQ[arg],  FileNames["*.wlt", arg, Infinity],
		FileExistsQ[arg], {arg},
		True,             {}
	]
];

With[{flag = SelectFirst[$args, StringStartsQ[#, "--file="] &, None]},
	$resolvedFiles = If[flag === None,
		Automatic,
		With[{entries = StringSplit[StringDrop[flag, StringLength["--file="]], ","]},
			Flatten[resolveFileArg /@ entries]
		]
	]
];

If[ListQ[$resolvedFiles] && Length[$resolvedFiles] === 0,
	Print["No test files found for --file argument."];
	Exit[1]
];

(* ── Color helper ──────────────────────────────────────────────────────── *)

c[directives___, s_String] :=
	If[$colorQ, Internal`StyleString[s, directives], s];

hr[] := c[GrayLevel[0.5], StringRepeat["\[LongDash]", 60]];

(* ── Header ────────────────────────────────────────────────────────────── *)

$mode = If[$fullQ, "Full", "Local"];

Print[""];
Print[c[Bold, "Unit Test Suite"] <> "  " <> c[GrayLevel[0.5], "(" <> $mode <> " mode)"]];
If[ListQ[$resolvedFiles],
	Module[{rel = StringDrop[#, StringLength[$testDir]] &, grouped, lastgroup},
		grouped = GroupBy[$resolvedFiles, DirectoryName @* rel];
		lastgroup = Last[grouped];
		Print[c[GrayLevel[0.5], "  Tests/"]];
		KeyValueMap[Function[{testdir, files},
			lastQ = files === lastgroup;
			If[testdir === "",
				If[lastQ,
					Scan[Print[c[GrayLevel[0.5], "  \:251C " <> rel[#]]] &, Most[files]];
					Print[c[GrayLevel[0.5], "  \:2514 " <> rel[Last[files]]]],
					Scan[Print[c[GrayLevel[0.5], "  \:251C " <> rel[#]]] &, Most[files]]
				]
				,
				Print[c[GrayLevel[0.5], "  \:251C " <> StringTrim[testdir, $PathnameSeparator] <> "/"]];
				If[lastQ,
					Scan[Print[c[GrayLevel[0.5], "  \:251C\:2500\:2500\:2500 " <> FileNameTake[#]]] &, Most[files]];
					Print[c[GrayLevel[0.5], "  \:2514\:2500\:2500\:2500 " <> FileNameTake[Last[files]]]]
					,
					Scan[Print[c[GrayLevel[0.5], "  \:251C\:2500\:2500\:2500 " <> FileNameTake[#]]] &, files]
				]
			]
		], grouped]
	]
];
Print[hr[]];
Print[""];

(* ── Load ──────────────────────────────────────────────────────────────── *)
testOpts = <||>;
testOpts["ReportType"] = $mode;
If[ ListQ[$resolvedFiles],
	testOpts["TestFiles"] = $resolvedFiles
];


(* ── Progress handler ───────────────────────────────────────────────────── *)

$progressFile   = None;
$progressCol    = 0;
$progressWidth  = 100;

$progressChar[result_] := With[{
	cat = UnitTestFramework`CategorizeTestResult[result]
},
	Switch[cat,
		"Success",            c[StandardGreen,  "."],
		"Failure",            c[StandardRed,    "x"],
		"PerformanceFailure", c[StandardRed,    "t"],
		"KnownIssue",         c[StandardYellow, "~"],
		"Fixed",              c[StandardBlue,   "*"],
		"Implemented",        c[StandardBlue,   "*"],
		_,                    c[GrayLevel[0.5], "."]   (* Skipped / NotImplemented *)
	]
];

testOpts["OnTestResult"] = Function[result,
	With[{file = Quiet @ result["TestFileName"]},
		(* New file — flush line and print header *)
		If[StringQ[file] && file =!= $progressFile,
			If[$progressCol > 0, WriteString["stdout", "\n"]];
			$progressFile = file;
			$progressCol  = 0;
			WriteString["stdout", c[GrayLevel[0.4], FileNameTake[file] <> "\n"]]
		];
		(* Inline character — flush and wrap if needed *)
		WriteString["stdout", $progressChar[result]];
		$progressCol++;
		If[$progressCol >= $progressWidth,
			WriteString["stdout", "\n"];
			$progressCol = 0
		]
	]
];

loadResult = Null;
$testResult = <||>;

If[ !TrueQ[$dryQ]
	,
	loadResult = Check[
		Get[$frameworkSource],
		$Failed
	];

	If[ FailureQ[loadResult],
		Print["UnitTestFramework.wl unavailable. Aborting"];
		Exit[1]
	];

	$testResult = UnitTestFramework`RunTests[
		FileNameJoin[{$testDir, "TestConfig.m"}],
		testOpts
	]
];

If[$progressCol > 0, Print["\n"]];

If[MatchQ[$testResult["TestReportObject"], _TestReportObject],
	If[!$dryQ || !FileExistsQ["last_test_run.wxf"],
		Export["last_test_run.wxf", $testResult["TestReportObject"]]
	]
];

If[And[
		$dryQ,
		FileExistsQ["last_test_run.wxf"],
		MatchQ[tmp = Import["last_test_run.wxf"], _TestReportObject]
	],
 	$testResult["TestReportObject"] = tmp;
]

(* ── Count results ─────────────────────────────────────────────────────── *)

$summary = $testResult["Summary"];
$groupedResults = UnitTestFramework`$GroupedResults;
countOf[key_] := AggregateRows[$summary, {"Total" -> (Total[#[key]] &)}][[1, "Total"]];

$nSuccess  = countOf["Success"];
$nFail     = countOf["Failure"];
$nPerfFail = countOf["PerformanceFailure"];
$nFixed    = countOf["Fixed"];
$nImpl     = countOf["Implemented"];
$nKnown    = countOf["KnownIssue"];
$nSkipped  = countOf["Skipped"];
$nNotImpl  = countOf["NotImplemented"];
$nSuccessTotal = $nSuccess + $nFixed + $nImpl

(* ── Print counts ──────────────────────────────────────────────────────── *)

pad[n_]  := StringPadLeft[ToString[n], 4];
lbl[s_]  := StringPadRight[s, 22];

Print[c[StandardGreen,                          "  [+]  " <> lbl["Success"]          <> pad[$nSuccess]]];
Print[c[If[$nFail > 0,     StandardRed, GrayLevel[0.5]],  "  [x]  " <> lbl["Failure"]          <> pad[$nFail]]];
Print[c[If[$nPerfFail > 0, StandardRed, GrayLevel[0.5]],  "  [t]  " <> lbl["Performance Fail"] <> pad[$nPerfFail]]];
If[$nFixed  > 0, Print[c[StandardBlue,          "  [*]  " <> lbl["Fixed (was known)"] <> pad[$nFixed]]]];
If[$nImpl   > 0, Print[c[StandardBlue,          "  [*]  " <> lbl["Implemented"]       <> pad[$nImpl]]]];
If[$nKnown  > 0, Print[c[StandardYellow,        "  [~]  " <> lbl["Known Issues"]      <> pad[$nKnown]]]];
If[$nSkipped  > 0, Print[c[GrayLevel[0.5], "  [.]  " <> lbl["Skipped"]        <> pad[$nSkipped]]]];
If[$nNotImpl  > 0, Print[c[GrayLevel[0.5], "  [.]  " <> lbl["Not Implemented"]<> pad[$nNotImpl]]]];

(* ── Failure details ───────────────────────────────────────────────────── *)

$failures = Join[
	Lookup[$groupedResults, "Failure",            {}],
	Lookup[$groupedResults, "PerformanceFailure", {}]
];

If[Length[$failures] > 0 && !$summaryQ,
	Print[""];
	Print[c[ParentDirectory @ DirectoryName @ $InputFileName, Bold, "Failures"]];
	Print[hr[]];
	Print[""];

	safeStr[expr_] := With[{s = Quiet @ Check[ToString[Unevaluated[expr], InputForm], "(unavailable)"]},
	shortStr[s, 300]
	];
	safeStr[expr_List] := safeStr /@ Unevaluated[expr];
	safeStr[HoldForm[expr_]] := safeStr[Unevaluated[expr]];

	shortStr[s_String, n_ : 20, side_ : Right] := If[StringLength[s] > n,
		If[side === Right,
			StringTake[s, n] <> " [...] ",
			StringTake[s, Ceiling[n/2]] <> " [...] " <> StringTake[s, Floor[n/2]]
		],
		s
	];

	(* renderDiff: inline colored diff using Diff[...]["SequenceAlignment"]
	   Alignment chunks: plain String = common, {exp, act} = change.
	   {exp, ""}  → deletion  (green, expected only)
	   {"",  act} → insertion (red,   actual only)
	   {exp, act} → replace   (green exp + red act)
	   Common parts ≤ $contextChars are shown as-is; longer ones collapse to …  *)
	$diffThreshold = 120;
	$contextChars  = 12;

	renderDiff[expDisp_String, actDisp_String, expFull_String, actFull_String] :=
		With[{align = Quiet @ Check[
				Diff[expFull, actFull, DiffIncludeMatches -> True]["SequenceAlignment"],
				$Failed
			]},
			With[{short = Max[StringLength[expDisp], StringLength[actDisp]] <= $diffThreshold},
				StringJoin @ {
					If[short || FailureQ[align],
						"      " <> c[StandardGreen, "Expected: "] <> expDisp <> "\n" <>
						"      " <> c[StandardRed,   "Actual:   "] <> actDisp,
						Nothing
					],
					If[!FailureQ[align],
						(If[short, "\n", ""] <>
						"      " <> c[GrayLevel[0.5], "Diff:     "] <>
						StringJoin[
							Replace[align, {
								""               :> Nothing,
								s_String         :> c[GrayLevel[0.6], shortStr[s, $contextChars, Center]],
								{e_String, ""}   :> c[StandardGreen, shortStr[e, 100, Center]],
								{"",  a_String}  :> c[StandardRed, shortStr[a, 100, Center]],
								{e_String, a_String} :> c[StandardGreen, e] <> c[StandardRed, a],
								e_               :> c[StandardOrange, ToString[e, InputForm]]
							}, {1}]
						]),
						Nothing
					]
				}
			]
		];

	printTest[test_, idx_] := (
		$id    = test["TestID"];
		$idStr = If[MissingQ[$id] || $id === None, "(no TestID)", ToString[$id]];

		Print[c[Bold, "  [" <> ToString[idx] <> "] " <> $idStr]
			<> "  " <> c[GrayLevel[0.5], ToString[test["Outcome"]]]];

		Print["      " <> c[GrayLevel[0.5], "Input:    "] <> safeStr[test["Input"]]];

		If[test["Outcome"] === "MessagesFailure",
			$expMsgs = Quiet @ test["ExpectedMessages"];
			$actMsgs = Quiet @ test["ActualMessages"];
			If[ListQ[$expMsgs] || ListQ @@ $expMsgs,
				Print["      " <> c[StandardGreen, "Exp.Msgs: "] <>
					StringRiffle[safeStr @ $expMsgs, "\n                "]]
			];
			If[ListQ[$actMsgs] || ListQ @@ $expMsgs,
				Print["      " <> c[StandardRed, "Act.Msgs: "] <>
					StringRiffle[safeStr @ $actMsgs, "\n                "]]
			]
			,
			$expDisp = safeStr[test["ExpectedOutput"]];
			$actDisp = safeStr[test["ActualOutput"]];
			$expFull = Quiet @ Check[ToString[test["ExpectedOutput"], InputForm], $expDisp];
			$actFull = Quiet @ Check[ToString[test["ActualOutput"],   InputForm], $actDisp];
			Print[renderDiff[$expDisp, $actDisp, $expFull, $actFull]];
			$actMsgs = Quiet @ test["ActualMessages"];
			If[ListQ[$actMsgs] && Length[$actMsgs] > 0,
				Print["      " <> c[StandardYellow, "Messages: "] <>
					StringRiffle[safeStr @ $actMsgs, "\n                "]]
			]
		];
		Print[""]
	);

	(* Group by file, printing each filename as a section header once *)
	$byFile = GroupBy[$failures, Replace[Quiet @ #["TestFileName"], Except[_String] -> "(unknown)"] &];
	$globalIdx = 0;
	KeyValueMap[
		Function[{file, tests},
			Print[c[GrayLevel[0.4], StringRepeat["\[LongDash]", 3] <> " "] <>
				c[Bold, FileNameTake[file]] <>
				c[GrayLevel[0.4], "  (" <> ToString[Length[tests]] <> ") " <> StringRepeat["\[LongDash]", 20]]];
			Print[""];
			Scan[printTest[#, ++$globalIdx] &, tests]
		],
		$byFile
	]
];

(* ── Final verdict ─────────────────────────────────────────────────────── *)

$totalFailed = $nFail + $nPerfFail;

Print[hr[]];
If[ TrueQ[$totalFailed === 0 && $testResult["ReportSucceeded"]],
	Print[c[StandardGreen, Bold, " PASSED "] <> "  " <> ToString[$nSuccessTotal] <> " test(s) passed"],
	Print[c[StandardRed,   Bold, " FAILED "] <> "  " <>
		ToString[$totalFailed] <> " failure(s)  |  " <> ToString[$nSuccessTotal] <> " passed"]
];
Print[""];

Exit[If[$totalFailed > 0, 1, 0]]
