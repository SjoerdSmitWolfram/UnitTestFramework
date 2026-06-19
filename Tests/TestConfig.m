(* 
	This file contains all of the user-customizable parts of the UnitTestFramework. RunTests expects to find this file in the Tests folder.
	This file should either have a definition of the UnitTestFramework`$TestConfig variable or it should just return an association.
*)

BeginPackage["UnitTestFramework`"]

$TestConfig


Begin["`Private`"]


$TestConfig = <|
	"AbortOnFail" -> False,
	"OnTestResult" -> Automatic,
	"ReportType" -> "Full",
	"SkipUnimplemented" -> False,
	"TestFiles" -> Automatic,
	"SkipGeneratedTests" -> False,
	"TestFileContext" -> "UnitTestFramework`TestRun`",
	"PacletDirectory" -> Automatic,
	"PacletContexts" -> "UnitTestFramework`",
	"TestEvaluationFunction" -> Automatic,
	"RandomSeeding" -> 1234,
	"TestCategorizationFunction" -> Automatic,
	"TestReportOptions" -> {},
	"PacletInitialization" -> Automatic,
	"TestDirectory" -> Automatic,
	"ExampleConfigFile" -> FileNameJoin[{ParentDirectory @ DirectoryName[$InputFileName], "Examples", "Tests", "TestConfig.m"}]
|>;


End[]

EndPackage[]


$TestConfig
