PackageExported["MyFunction"]
PackageScoped["MyFunctionInternal"]

ClearAll @@ Names["ExamplePaclet`" ~~ __];

(* This line is used to simulate a bug in the function *)
MyFunction[3] := 5;

(* This line is used to simulate feature that hasn't been implemented yet *)
MyFunction[4] := Failure["NotImplemented", <||>];

MyFunction[x_] := Module[{
	val = x
},
	Enclose[
		ConfirmBy[MyFunctionInternal[val], EvenQ] / 2
	]
];


MyFunctionInternal[x_] := x^2

