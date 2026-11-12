# UnitTestFramework Test Runner

This repository contains a reusable Wolfram Language test runner for paclet-style projects.

- Paclet: [`UnitTestFramework`](UnitTestFramework) (source file: [`UnitTestFramework/Kernel/UnitTestFramework.wl`](UnitTestFramework/Kernel/UnitTestFramework.wl))
- Package context: ``UnitTestFramework` ``
- Main entry point: `RunTests[configFile]`
- Test tagging function: `TagTest`
- Requires Wolfram Language 15.0 or later

## What this is for

`UnitTestFramework.wl` is designed to be loaded once and configured per project via a test config file so you get:

- Automatic discovery of `.wlt`/`.mt` test files
- Per-test metadata tagging via `TagTest`
- Configurable skipping behavior (for generated, unimplemented, and performance tests)
- Optional abort-on-first-failure behavior
- A filtered test report suitable for CI pass/fail decisions
- A summary view with categorized results

The runner expects a paclet-style project layout with a `PacletInfo.wl` file and a `Tests/` directory containing the test configuration and `.wlt` files.

This repository also contains a small example paclet [`Examples/ExamplePaclet`](Examples/ExamplePaclet) with a `Tests/` folder and a `TestConfig.m` file, along with an example `.wlt` file and a test runner script [`run_tests.wls`](Examples/Tests/run_tests.wls) that demonstrates how to run the tests from the command line.

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
4. Configure the `TestConfig` file as needed. It can be either a Wolfram file that defines `$TestConfig` or any other file that returns an association.
5. If you use a Wolfram file, you can further customize the runner by defining your own test evaluation function and/or test categorization function.
6. Optionally add an untracked `LocalConfig.*` file in `Tests/` for machine-specific settings such as local dependency roots.
7. Load the framework and run tests by evaluating:
  - `Get["path/to/UnitTestFramework.wl"]` (use the path https://raw.githubusercontent.com/SjoerdSmitWolfram/UnitTestFramework/refs/heads/main/UnitTestFramework/Kernel/UnitTestFramework.wl to load directly from GitHub)
  - ``UnitTestFramework`RunTests["path/to/Tests/TestConfig.m"]``

## Config Keys

The main keys supported by `TestConfig` are:

- `"AbortOnFail"`: stop after the first unexpected failure.
- `"OnTestResult"`: callback applied to each produced test result.
- `"ReportType"`: controls breadth of the run, for example `"Full"` versus a quicker `"Local"` run. The full test will include all tests, while a local run may skip performance tests and other long-running cases.
- `"SkipTags"`: tags to skip, given as a single tag, a list of tags, or an association of tags to booleans. Default value is `None`. Tests tagged `"Skip"` are always skipped, regardless of this setting.
- `"TestSections"`: test sections to run, given as a list of section titles or a pattern. Default value is `All`.
- `"TestDirectory"`: main directory containing the test files. Defaults to the directory containing the config file.
- `"TestFiles"`: test files to run. Use `All` to discover all test files recursively under `Tests/`, or provide explicit paths relative to `"TestDirectory"`.
- `"TestFilePattern"`: File pattern to use to detect test files to run. Only has any effect if `"TestFiles" -> All`  is used. Defaults to `"*.wlt" | "*.mt"`.
- `"RunFirstFiles"`: List of .wlt files to run first. These files can be used, for example, to specify "CanaryTest" tagged tests to fail early in case of egregious problems. Specified in the same way as `"TestFiles"`, relative to `"TestDirectory"`.
- `"TestFileContext"`: base `$Context` used while evaluating tests. Each test file gets its own sub-context under it. Defaults to ``"UnitTestFramework`TestRun`"``.
- `"PacletDirectory"`: paclet root directory. When `Automatic`, the runner looks for `PacletInfo.wl` above `Tests/`.
- `"PacletContexts"`: contexts to put on `$ContextPath` while running tests. Defaults to the contexts defined in `PacletInfo.wl`. The first context is the one loaded by `"PacletInitialization" -> Automatic`. The contexts ``UnitTestFramework` ``, ``MUnit` `` and ``System` `` are always on `$ContextPath` as well.
- `"PacletContextAliases"`: Optional Association that will be used as the value for `$ContextAliases` while running the tests.
- `"TestEvaluationFunction"`: evaluation function that is used inside `TestEvaluator`, which is the default handler for test evaluation in UnitTestFramework. Defaults to `TestEvaluate`. If you want to circumvent `TestEvaluator` altogether, use the `"TestReportOptions"` property to pass a custom `TestEvaluationFunction` to `TestReport`.
- `"RandomSeeding"`: seed used when running the tests. The random generator is re-seeded at the start of each test file. Defaults to `1234`.
- `"TestCategorizationFunction"`: function used to label test results. Defaults to `CategorizeTestResult`.
- `"TestReportOptions"`: options forwarded to `TestReport`.
- `"PacletInitialization"`: initialization code run before tests execute.
- `"IgnoreLocalConfig"`: when `True`, disables loading of a `LocalConfig.*` file from the test directory.
- `"LocalDependenciesRoot"`: one or more directories that contain local development paclets.
- `"LocalDependencies"`: one or more paclet contexts to resolve from `"LocalDependenciesRoot"` and load via `PacletDirectoryLoad`.

`"TestCategorizationFunction"`, `"PacletInitialization"`, `"TestEvaluationFunction"`, `"OnTestResult"`, and `"TestReportOptions"` may contain Wolfram code. If you use a non-Wolfram config format, those values can also be given as `InputForm` strings that will be converted with `ToExpression`.

`"PacletInitialization"` supports three forms:

- `Automatic`: evaluates `Get[pacletContext]` using the inferred paclet context.
- `Function[...]`: receives the fully resolved test config association.
- `Hold[...]`: held code that is released after config initialization.

## Local config overrides

If your project needs machine-specific test configuration, you can place a `LocalConfig.*` file in the same directory as `TestConfig`.

- The file is optional and intended to remain untracked.
- It is loaded after the main `TestConfig`, so its properties override earlier values.
- It can use the same supported formats as `TestConfig`.
- Set `"IgnoreLocalConfig" -> True` to disable this behavior.

This is useful for settings that differ per developer, such as paths to locally checked out paclet dependencies. In particular, the `"LocalDependenciesRoot"` is normally set in `LocalConfig` so that each developer can point to their own local paclet checkouts without committing those paths to the shared test configuration.

### Local development dependencies

The local config mechanism is designed to work with local paclet dependencies:

- `"LocalDependenciesRoot"` accepts one or more directories that contain local paclet checkouts.
- `"LocalDependencies"` lists the paclet contexts that should be resolved from those directories.
- Matching paclets are located by their `PacletInfo.wl` files (up to 3 levels deep from the root) and loaded with `PacletDirectoryLoad` before paclet initialization runs.

This lets each developer point tests at local working copies of dependent paclets without committing those paths to the shared test configuration.

As part of the initialization, the runner will also set `$TestConfig` to the fully resolved config association. In it, `"TestFiles"` and `"RunFirstFiles"` are resolved to absolute paths, and the following properties are added:

- `"TestConfigFile"`: the absolute path to the config file (`None` if no config file was used).
- `"LocalConfigFile"`: the file name of the `LocalConfig.*` file that was loaded, or `None`.
- `"PacletObject"`: the symbolic representation of the `PacletInfo.wl` file.
- `"LocalDependenciesLoaded"`: the result of `PacletDirectoryLoad` for the local dependencies.

`$TestConfigDefaults` holds the default values of all config keys.

## Important conventions

- Use `TestCreate` for test definitions. Do not use the old symbol `VerificationTest` because it does not support the new features.
- Use metadata tags to control evaluation behavior of your tests and how tests are reported in the summary.
- Give every test a `TestID` that is unique across the whole test suite. Results, timings and metadata are stored by `TestID`, so a duplicate would overwrite another test's entries. The runner issues a `RunTests::duptestid` message for each duplicate and lists them under `"NonUniqueTestIDs"` in the output.

## Where files should live

`TestConfig` should live in each target project's test root, typically:

- `Tests/TestConfig.m`

An optional untracked local override file can live alongside it:

- `Tests/LocalConfig.m`

`UnitTestFramework.wl` does not need to be copied into every project. Path resolution is based on the config file (`"TestDirectory"` defaults to that file's directory). Loading can be done by installing it as a paclet or by simply using `Get["path/to/UnitTestFramework.wl"]`. 

The example paclet in this repository (`Examples/ExamplePaclet`) has a `Tests/` folder with a `TestConfig.m` file and some example `.wlt` files. It also contains an example test runner script `run_tests.wls` that demonstrates how to run the tests from the command line. You can use that as a template for your own project, but note that these files may need to be modified to match the requirements for your specific project. The test script also produces a file `last_test_run.wxf` that holds the output of the most recent test suite in case you need to retrieve detailed information.

## Running tests

### Default run

```wl
UnitTestFramework`RunTests["path/to/Tests/TestConfig.m"]
```

By default this:

- Loads/initializes paclet contexts (unless configured otherwise)
- Finds all `.wlt`/`.mt` files under the configured test directory
- Defines a unique context for each test file based on its path to avoid symbol clashes
- Evaluates using the custom `TestEvaluator`
- Produces an association with keys:
  - `"ReportSucceeded"`: whether the test suite passed according to the filtered report
  - `"TestReportObject"`: filtered report used for automated pass/fail (see [CI behavior](#ci-behavior))
  - `"Summary"`: `Tabular` summary of the number of test results per file and category, with a final `"Total"` row
  - `"GroupedResults"`: association of categories to `TestReportObject`s containing all test results in that category
  - `"TestConfiguration"`: the fully resolved test configuration association
  - `"$TestSuiteAbortedQ"`: whether the test suite was aborted mid-run (e.g., if a failure occurred while `"AbortOnFail"` is `True`)
  - `"TestFilesWithFailures"`: association of test files (relative to the test directory) that contain failures, with the number of `"Failure"` and `"PerformanceFailure"` results in each
  - `"TestFileContexts"`: association of test files to the contexts they were evaluated in, plus a `"DefaultContexts"` key with the `$ContextPath` used during the run
  - `"TestTimings"`: association of `TestID`s to the evaluation time in seconds (only for tests that were evaluated)
  - `"TestMetadata"`: association of `TestID`s to the `MetaInformation` of each test, including tags and `"TestSection"`
  - `"NonUniqueTestIDs"`: list of `TestID`s that occur more than once in the test suite

The same association is stored in `$RunTestsOutput`. If the configuration is invalid, `RunTests` returns a `Failure`.

### Other ways to call RunTests

- `RunTests[configFile, overrides]`: overrides values in the config file, where `overrides` is an association or a sequence of rules.
- `RunTests[testDirectory, overrides]`: uses `testDirectory` as the test directory and looks there for a file whose name starts with `TestConfig`. If there are several, a dialog asks which one to use. If there are none, a message is issued and the tests run with default settings.
- `RunTests[None, overrides]`: takes all configuration from `overrides`.
- `RunTests[testFiles, overrides]`: runs only the given `.wlt`/`.mt` file or files, with configuration taken from `overrides`. If no `"TestDirectory"` is given, the directory of the test files is used.

### Running from the command line

[`Examples/Tests/run_tests.wls`](Examples/Tests/run_tests.wls) is a script you can copy into your own `Tests/` folder. It prints progress while the tests run, followed by a summary and the details of each failure, and exits with a nonzero exit code if the suite fails. Run it with:

```text
wolframscript -file Tests/run_tests.wls [flags]
```

| Flag | Effect |
|:--|:--|
| `--local` | Set `"ReportType" -> "Local"`, which skips performance and full-report-only tests |
| `--abort` | Set `"AbortOnFail" -> True` |
| `--file=FILE[,FILE...]` | Run only these files or folders, relative to `Tests/` |
| `--cf=FILE` | Use this config file, relative to `Tests/` |
| `--summary` | Print only the counts, not the details of each failure |
| `--no-color` | Disable terminal colors |
| `--dry-run` | Do not run the tests, but show the results of the previous run from `last_test_run.wxf` |
| `--usage` | Print the list of flags |

The script loads the framework from GitHub by default. Change `$frameworkSource` at the top of the script to use a local copy: either the path to `UnitTestFramework.wl` or the paclet directory.

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

Tags are stored in the test's `MetaInformation` and can be used to control test execution and reporting behavior. The `MetaInformation` of tests will also be automatically populated with a `"TestSection"` key if the test is defined between `BeginTestSection[...]` and `EndTestSection[...]` calls. This allows you to group tests into sections and control abort behavior for each section separately.

## Test result categorizations

`CategorizeTestResult` is used by the runner to turn each test result into a display category. The possible categories are:

- `Success`: test evaluated as expected
- `Failure`: test evaluated not as expected
- `KnownIssue`: test failed, but this was expected because of a bug (for tests tagged `"KnownMessageIssue"`, only when the outcome is `"MessagesFailure"`)
- `NotImplemented`: test failed because the feature hasn't been implemented yet
- `PerformanceFailure`: test failed because of time or memory constraint
- `Fixed`: a `KnownIssue` or `KnownMessageIssue` test that now passes
- `Implemented`: a `NotImplemented` test that now passes
- `Skipped`: test did not run

These categories are what `TestReportSummary[]` shows. `$TestReport` leaves out the `KnownIssue` and `NotImplemented` results, so you can use it for CI pass/fail decisions. The full `$TestResults` contains all tests with their original `TestObject` values, so you can use it for more detailed reporting and analysis. `$GroupedResults` holds all results grouped by category.

## Common tags

Built-in tag meanings (from `$TestTags`):

- `"Skip"`: do not run this test (unless explicitly set to `"Skip" -> False`, which forces the test to run even if it would normally be skipped).
- `"NotImplemented"`: expected fail until feature exists.
- `"KnownIssue"`: known failing case that should still run.
- `"KnownMessageIssue"`: like `"KnownIssue"`, but only for tests that produce the correct result while issuing unexpected messages. The test is reported as `KnownIssue` if its outcome is `"MessagesFailure"`, but as a regular `Failure` if the result itself is wrong (outcome `"Failure"`).
- `"CanaryTest"`: if this test fails, the suite should abort immediately because there will be many failures afterwards. This is useful for tests that are known to be fragile or that indicate a serious problem if they fail.
- `"SectionCanaryTest"`: same as `"CanaryTest"`, but only aborts the current section (as delineated by `BeginTestSection[...]` and `EndTestSection[]`) of tests instead of the entire suite.
- `"PerformanceTest"`: long-running or constrained test. Tests with explicitly specified options for `MemoryConstraint` or `TimeConstraint` are also considered performance tests. Performance tests will be skipped in quick/local reports.
- `"FullReportOnly"`: skip in quick/local reports.
- `"BreakPoint"`: stop suite at this test for debugging.
- `"GeneratedTest"`: machine-generated test case.

Any other tag can be used as well. It has no effect on evaluation, but it can be skipped with `"SkipTags"` and is available to a custom categorization function.

## Summary and cleanup helpers

- `TestReportSummary[]` summarizes the latest run by file and category. `TestReportSummary[report]` does the same for any `TestReportObject`.
- `CombineReports[res1, res2, ...]` combines `TestObject`s, `TestReportObject`s, or lists of them into a single `TestReportObject` without re-evaluating the tests.
- `LoadTestContexts[]` puts the contexts of the test files with failures from the latest run back on `$ContextPath`, so that symbols in the failed tests print without their full context.
- `DropTestContexts[]` removes all test file contexts from `$ContextPath` again.
- `PostTestCleanUp[]` clears the symbols in all generated test contexts and removes those contexts from `$ContextPath`.
- `ToDecimalDigits[expr, n]` rounds all numbers in `expr` to at most `n` digits after the decimal point (default 4), which helps make numerical test results reproducible.

## CI behavior

The runner builds a filtered `$TestReport` that contains every result except the `"KnownIssue"` and `"NotImplemented"` categories. Only `"Failure"` and `"PerformanceFailure"` results make it fail. `"Skipped"` tests are not evaluated and don't count as failures, and `"Fixed"` and `"Implemented"` results count as successes. The `"ReportSucceeded"` value of the output can be used directly as the pass/fail result.

## Extending and customizing

The runner can be customized through the config file:

- Use `"TestEvaluationFunction"` to change how each test is evaluated, while keeping the tag handling of `TestEvaluator`.
- Use `"TestCategorizationFunction"` to change how results are categorized, for example to handle your own tags. It can build on `CategorizeTestResult`.
- Use `"OnTestResult"` for logging or progress reporting. It is called with each test result as soon as it is produced, including skipped tests.
- Use `"SkipTags"` to skip tests with your own tags.

`$TestTags` only holds descriptions of the built-in tags. Adding entries to it does not change any behavior.

## Other notes and tips

- Use `ResourceFunction["TestReportNotebook"] @ $TestReport` to get a detailed notebook report of the latest test run and debug failures.
- `ResourceFunction["OpenTestWritingPalette"][]` opens a palette with tools that make it easy to write tests by copying input-output examples from a notebook and converting them into `TestCreate` calls.
