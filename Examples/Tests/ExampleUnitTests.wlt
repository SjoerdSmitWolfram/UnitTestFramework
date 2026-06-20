(* ========================================================================= *)
(* Basic tests                                                                *)
(* ========================================================================= *)

TestCreate[
	MyFunction[6]
	,
	18
	,
	TestID -> "Basic-Success"
]

TestCreate[
	MyFunction[5]
	,
	_?FailureQ
	,
	TestID -> "Basic-OddInputReturnsFailure",
	SameTest -> MatchQ
]

TestCreate[
	(* 
		If you want to avoid having to name internal symbols by their fully qualified name, add the internal context to the "PacletContexts" 
		property in the TestConfig file.
	*)
	ExamplePaclet`PackageScope`MyFunctionInternal[5]
	,
	25
	,
	TestID -> "Basic-PackageScopeFunction"
]


(* ========================================================================= *)
(* KnownIssue examples                                                        *)
(* ========================================================================= *)

(* The example paclet has a deliberate bug: MyFunction[3] := 5. *)
TestCreate[
	MyFunction[3]
	,
	_?FailureQ
	,
	TestID -> "KnownIssue-FailingCase",
	SameTest -> MatchQ
] // TagTest["KnownIssue"]

(* When the bug is fixed, this test will show up as "Fixed". *)
TestCreate[
	MyFunction[6]
	,
	18
	,
	TestID -> "KnownIssue-AlreadyFixed"
] // TagTest["KnownIssue"]


(* ========================================================================= *)
(* NotImplemented examples                                                    *)
(* ========================================================================= *)

(* Represents a feature that still returns a failure for odd values. *)
TestCreate[
	MyFunction[7]
	,
	_?FailureQ
	,
	TestID -> "NotImplemented-FailingCase",
	SameTest -> MatchQ
] // TagTest["NotImplemented"]

(* If behavior is available already, this is categorized as "Implemented". *)
TestCreate[
	MyFunction[8]
	,
	32
	,
	TestID -> "NotImplemented-AlreadyImplemented"
] // TagTest["NotImplemented"]


(* ========================================================================= *)
(* Skip / GeneratedTest examples                                              *)
(* ========================================================================= *)

(* Always skipped unless explicitly forced with "Skip" -> False. *)
TestCreate[
	MyFunction[2]
	,
	2
	,
	TestID -> "Skip-ExplicitTrue"
] // TagTest["Skip" -> True]

(* Demonstrates that explicit Skip -> False overrides skip logic. *)
TestCreate[
	MyFunction[2]
	,
	2
	,
	TestID -> "Skip-ExplicitFalse"
] // TagTest["Skip" -> False, "GeneratedTest"]

(* Generated tests can be globally skipped via SkipGeneratedTests. *)
TestCreate[
	ExamplePaclet`PackageScope`MyFunctionInternal[10]
	,
	100
	,
	TestID -> "GeneratedTest-Example"
] // TagTest["GeneratedTest"]


(* ========================================================================= *)
(* Report-type based examples                                                 *)
(* ========================================================================= *)

(* Skipped in local runs (ReportType != "Full"), runs in full reports. *)
TestCreate[
	MyFunction[10]
	,
	50
	,
	TestID -> "PerformanceTest-OnlyInFull"
] // TagTest["PerformanceTest"]

(* Another way to limit tests to the full report mode. *)
TestCreate[
	MyFunction[12]
	,
	72
	,
	TestID -> "FullReportOnly-OnlyInFull"
] // TagTest["FullReportOnly"]

(* A test with TimeConstraint is automatically considered a performance test. *)
TestCreate[
	Pause[0.02];
	MyFunction[4]
	,
	8
	,
	TestID -> "PerformanceTest-FromConstraint",
	TimeConstraint -> 1
]


(* ========================================================================= *)
(* Multiple tags at once                                                      *)
(* ========================================================================= *)

(* This demonstrates multi-tag metadata and explicit booleans. *)
TestCreate[
	MyFunction[3]
	,
	_?FailureQ
	,
	TestID -> "MultiTag-KnownIssueAndGenerated",
	SameTest -> MatchQ
] // TagTest["KnownIssue", "GeneratedTest" -> True, "Skip" -> False]

