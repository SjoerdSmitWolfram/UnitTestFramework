(* 
	This file contains all of the user-customizable parts of the UnitTestFramework. RunTests expects to find this file in the Tests folder.
	This file should either have a definition of the UnitTestFramework`$TestConfig variable or it should just return an association.

	The pre-defined properties in this file should work for most standard projects without further modification.
*)

BeginPackage["UnitTestFramework`"]

$TestConfig


Begin["`Private`"]


$TestConfig = <|
	(* The paclet related properties are the most important ones to check when setting up a new project *)
	"PacletContexts" -> Automatic,
	"PacletDirectory" -> Automatic,
	"PacletInitialization" -> Automatic,
	
	"TestDirectory" -> Automatic,
	"TestFiles" -> Automatic,

	"AbortOnFail" -> False,
	"OnTestResult" -> Automatic,
	"ReportType" -> "Full",
	"SkipUnimplemented" -> False,
	"SkipGeneratedTests" -> False,
	
	"TestEvaluationFunction" -> Automatic,
	"RandomSeeding" -> 1234,
	"TestCategorizationFunction" -> Automatic,
	"TestReportOptions" -> {},
	"TestFileContext" -> Automatic
|>;


End[]

EndPackage[]


$TestConfig
