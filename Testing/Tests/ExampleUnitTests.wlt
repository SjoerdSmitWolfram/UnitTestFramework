TestCreate[
	MyFunction[6]
	,
	18
	,
	TestID->"Test-1"
]

TestCreate[
	MyFunction[5]
	,
	_?FailureQ
	,
	TestID->"Test-2",
	SameTest -> MatchQ
]


(* 
	Example of tagging a test. The function has been deliberately polluted with a wrong definition. This has been tagged as a known issue that 
	needs to be fix later
*)
TestCreate[
	MyFunction[3]
	,
	_?FailureQ
	,
	TestID->"Test-3",
	SameTest -> MatchQ
] // TagTest["KnownIssue"]


TestCreate[
	MyFunctionInternal[5]
	,
	25
	,
	TestID->"Test-4"
]

