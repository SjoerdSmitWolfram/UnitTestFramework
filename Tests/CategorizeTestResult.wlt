Clear[categorize, messageFun];

messageFun::warn = "Unexpected message.";
messageFun[x_] := (Message[messageFun::warn]; x);

(* Evaluate a test with the given tags and return its category *)
categorize[test_TestObject, tags___] := CategorizeTestResult[TestEvaluate[TagTest[tags][test]]];

(* Use SetDelayed so these tests are only created inside the actual tests and don't become part of the test suite *)
$categorizationTests := <|
	"Success" -> TestCreate[1, 1],
	"Failure" -> TestCreate[1, 2],
	"MessagesFailure" -> TestCreate[messageFun[1], 1],
	"FailureWithMessages" -> TestCreate[messageFun[1], 2]
|>;

TestCreate[
	Map[categorize, $categorizationTests]
	,
	<|"Success" -> "Success", "Failure" -> "Failure", "MessagesFailure" -> "Failure", "FailureWithMessages" -> "Failure"|>
	,
	TestID -> "CategorizeTestResult-Untagged"
]

TestCreate[
	Map[categorize[#, "KnownIssue"]&, $categorizationTests]
	,
	<|"Success" -> "Fixed", "Failure" -> "KnownIssue", "MessagesFailure" -> "KnownIssue", "FailureWithMessages" -> "KnownIssue"|>
	,
	TestID -> "CategorizeTestResult-KnownIssue"
]

(* Only a "MessagesFailure" outcome counts as a known issue for "KnownMessageIssue" *)
TestCreate[
	Map[categorize[#, "KnownMessageIssue"]&, $categorizationTests]
	,
	<|"Success" -> "Fixed", "Failure" -> "Failure", "MessagesFailure" -> "KnownIssue", "FailureWithMessages" -> "Failure"|>
	,
	TestID -> "CategorizeTestResult-KnownMessageIssue"
]

TestCreate[
	Map[categorize[#, "NotImplemented"]&, $categorizationTests]
	,
	<|"Success" -> "Implemented", "Failure" -> "NotImplemented", "MessagesFailure" -> "NotImplemented", "FailureWithMessages" -> "NotImplemented"|>
	,
	TestID -> "CategorizeTestResult-NotImplemented"
]
