# UnitTestFramework Test Runner

This folder contains a reusable Wolfram Language test runner for paclet-style projects.

- Source file: `UnitTestFramework.wl`
- Package context: ``UnitTestFramework` ``
- Main entry point: `RunTests[configFile]`
- Test tagging function: `TagTest`

## What this is for

`UnitTestFramework.wl` is designed to be loaded once and configured per project via a test config file so you get:

- Automatic discovery of `.wlt`/`.mt` test files
- Per-test metadata tagging via `TagTest`
- Configurable skipping behavior (for generated, unimplemented, and performance tests)
- Optional abort-on-first-failure behavior
- A filtered test report suitable for CI pass/fail decisions
- A summary view with categorized results

## Recommended project layout

Place your project files like this:

```text
root/
├── PacletDir/
    │   ├── Kernel/
    │   │   └── ... your .wl source files
│   └── PacletInfo.wl
└── Tests/
    ├── TestConfig (any format that can be imported as an association)
    └── ... your *.wlt files (in any subfolder)
```

The runner assumes all test files are under the configured `"TestDirectory"` (which defaults to the directory containing the config file) and discovers them with:

- `FileNames["*.wlt" | "*.mt", testDirectory, Infinity]`

## Setup steps

1. Place a `TestConfig` file in your project's `Tests/` directory.
2. Add your unit tests as `.wlt` files under `Tests/` (subfolders are supported).
3. Define tests using `TestCreate[...]`.
4. Configure the `TestConfig` file as needed (for example `"PacletDirectory"`, `"PacletContexts"`, `"ReportType"`, and skip options).
5. Load the framework and run tests by evaluating:
  - `Get["path/to/UnitTestFramework.wl"]`
  - ``UnitTestFramework`RunTests["path/to/Tests/TestConfig.wl"]``

## Important conventions

- Prefer `TestCreate` for test definitions.
- Do not use `VerificationTest` for new tests (legacy style).
- Use metadata tags to control behavior during local/full runs.

## Where files should live

`TestConfig` should live in each target project's test root, typically:

- `Tests/TestConfig.wl`

`UnitTestFramework.wl` does not need to be copied into every project. Path resolution is based on the config file (`"TestDirectory"` defaults to that file's directory). Loading can be done by installing it as a paclet or by simply using `Get["path/to/UnitTestFramework.wl"]`.

## Running tests

### Default run

```wl
UnitTestFramework`RunTests["path/to/Tests/TestConfig.wl"]
```

By default this:

- Loads/initializes paclet contexts (unless configured otherwise)
- Finds all `.wlt`/`.mt` files under the configured test directory
- Defines a unique context for each test file based on its path to avoid symbol clashes
- Evaluates using the custom `TestEvaluator`
- Produces:
  - `$TestResults` (raw report from the built-in function `TestReport`)
  - `$TestReport` (filtered report used for automated pass/fail)

### Useful options

`RunTests` supports options such as:

- `"PacletDirectory"`: path to paclet for context loading (default: auto-detected from nearby `PacletInfo.wl`)
- `"PacletContexts"`: context path to use while running tests (default: `Automatic` to infer from paclet directory name)
- `"PacletInitialization"`: custom code to initialize the paclet. Should be a `Function` (which will be called with the paclet directory as an argument) or a `Hold` expression (which wil be released).
- `"AbortOnFail"`: whether to stop the test suite on the first unexpected failure (default: `False`)
- `"ReportType"`: for example `"Local"` vs `"Full"` suite behavior
- `"TestReportOptions"`: options to pass to `TestReport`
- `"SkipUnimplemented"`: whether to skip tests marked as not implemented (default: `False`)
- `"SkipGeneratedTests"`: whether to skip generated tests (default: `False`)
- `"OnTestResult"`: callback function to handle individual test results

## Tagging tests with TagTest

Use `TagTest` to annotate tests with metadata used by the custom evaluator.

Example:

```wl
TestCreate[
	Total @ RandomReal[1, 10^6]
	,
	_?NumericQ,
	SameTest -> MatchQ
] // TagTest["PerformanceTest"]
```

This marks the test as a performance test. In non-full reports, performance tests may be skipped depending on your `"ReportType"` and skip settings. 

Multiple tags can be set by using `TagTest[tag1, tag2, ...]`. Tags can also be given values, for example `TagTest["Skip" -> True]` to explicitly mark a test to be skipped, or `TagTest["Skip" -> False]` to force it to run even if it would normally be skipped. The default tag values is `True`, so `TagTest[tag1, ...]` is equivalent to `TagTest[tag1 -> True, ...]`.

Tags are stored in the test's `MetaInformation` and can be used to control test execution and reporting behavior.

## Test result categorizations

`CategorizeTestResult` is used by the runner to turn each test result into a display category. The possible categories are:

- `Success`: test evaluated as expected
- `Failure`: test evaluated not as expected
- `KnownIssue`: test failed, but this was expected because of a bug
- `NotImplemented`: test failed because the feature hasn't been implemented yet
- `PerformanceFailure`: test failed because of time or memory constraint
- `Fixed`: a `KnownIssue` test that now passes
- `Implemented`: a `NotImplemented` test that now passes
- `Skipped`: test did not run

These categories are what `TestReportSummary[]` shows. `$TestReport` will only include `Success`, `Failure`, and `PerformanceFailure` results, so you can use it for CI pass/fail decisions. The full `$TestResults` contains all tests with their original `TestResultObject` values, so you can use it for more detailed reporting and analysis.

## Common tags

Built-in tag meanings (from `$TestTags`):

- `"Skip"`: do not run this test (unless explicitly set to `"Skip" -> False`, which forces the test to run even if it would normally be skipped).
- `"NotImplemented"`: expected fail until feature exists.
- `"KnownIssue"`: known failing case that should still run.
- `"PerformanceTest"`: long-running or constrained test. Tests with explicitly specified options for `MemoryConstraint` or `TimeConstraint` are also considered performance tests. Performance tests will be skipped in quick/local reports.
- `"FullReportOnly"`: skip in quick/local reports.
- `"BreakPoint"`: stop suite at this test for debugging.
- `"GeneratedTest"`: machine-generated test case.

## Summary and cleanup helpers

- `TestReportSummary[]` summarizes latest run by file/category.
- `PostTestCleanUp[]` clears generated test contexts and symbols.

## CI behavior

The runner builds a filtered `$TestReport` containing only:

- `"Success"`
- `"Failure"`
- `"PerformanceFailure"`

This makes pass/fail automation straightforward.

## Extending and customizing

The runner is designed to be easily extended and customized. You can:
- Define new tags and their meanings in `$TestTags`.
- Customize test categorization logic in `CategorizeTestResult`.
- Customize the evaluator behavior in the `TestEvaluator` function.

## Other notes and tips

- Use `ResourceFunction["TestReportNotebook"] @ $TestReport` to get a detailed notebook report of the latest test run and debug failures.
- `ResourceFunction["OpenTestWritingPalette"][]` opens a palette with tools that make it easy to write tests by copying input-output examples from a notebook and converting them into `TestCreate` calls.
