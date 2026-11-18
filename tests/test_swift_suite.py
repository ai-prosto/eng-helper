"""Pytest bridge to the Swift test suite.

The project is a Swift package (see spec 20-design.md): the real tests live
in Tests/EngHelperKitTests and run under `swift test`. CI verification here
is pytest-based, so this module runs the Swift suite once and re-reports
each required Swift test as a pytest test.

With Command Line Tools only (no Xcode), swiftc does not auto-load the
Swift Testing macro plugin; the dylib ships with CLT but must be passed
explicitly via -load-plugin-library.
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent

CLT_TESTING_MACROS = Path(
    "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins"
    "/testing/libTestingMacros.dylib"
)

# TASK-001 and TASK-002 group checks plus TASK-003 unit tests: these
# Swift tests must be green.
REQUIRED_TESTS = [
    # TASK-001
    "testBuildsCardWithIPAGlossAndGroupedMeanings",
    "testExamplePresentOnlyWhenPayloadHasOne",
    "testRequestsFreeDictionaryURLWithoutKey",
    "testMapsTransportFailuresToLookupErrors",
    "testEmptyGlossPayloadIsNotFound",
    # TASK-002
    "testCreatesFolderAndWritesVocabularyFile",
    "testEntryStoresWordGlossDateIPAAndMeanings",
    "testFileIsValidPrettyPrintedJSONArray",
    "testFailedLookupWritesNothing",
    "testCaseInsensitiveDuplicateKeepsOneEntryAndFirstDate",
    "testWordFormsAreSeparateEntries",
    "testEntriesNewestFirst",
    "testEntryRebuildsCardWithoutNetwork",
    # TASK-003 (the group check itself is manual: docs/manual/popover-checks.md)
    "testSubmitLooksUpShowsCardAndSaves",
    "testBlankInputDoesNothing",
    "testOfflineFailureShowsOneLineAndWritesNothing",
    "testNotFoundFailureShowsOneLineAndWritesNothing",
    "testListIsNewestFirstAndReopensCardWithoutTransport",
    "testStaleLookupDoesNotOverwriteShownSavedCard",
    "testBadResponseAndUnknownFailureMessages",
    "testStoragePathsResolveApplicationSupportEngHelper",
]


def swift_test_command() -> list[str]:
    command = ["swift", "test"]
    if CLT_TESTING_MACROS.exists():
        command += [
            "-Xswiftc", "-load-plugin-library",
            "-Xswiftc", str(CLT_TESTING_MACROS),
        ]
    return command


@pytest.fixture(scope="session")
def swift_run() -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        swift_test_command(),
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        timeout=600,
        check=False,
    )


@pytest.fixture(scope="session")
def passed_tests(swift_run: subprocess.CompletedProcess[str]) -> set[str]:
    output = swift_run.stdout + swift_run.stderr
    return set(re.findall(r"Test (\w+)\(\) passed", output))


def test_swift_suite_is_green(
    swift_run: subprocess.CompletedProcess[str],
    passed_tests: set[str],
) -> None:
    assert swift_run.returncode == 0, (
        f"`{' '.join(swift_test_command())}` failed "
        f"(exit {swift_run.returncode}):\n"
        f"{swift_run.stdout[-4000:]}\n{swift_run.stderr[-4000:]}"
    )
    assert passed_tests, (
        "swift test exited 0 but no 'Test <name>() passed' lines were found; "
        "the output format this bridge parses has changed:\n"
        f"{swift_run.stdout[-4000:]}\n{swift_run.stderr[-4000:]}"
    )


@pytest.mark.parametrize("name", REQUIRED_TESTS)
def test_required_swift_test_passed(
    name: str,
    swift_run: subprocess.CompletedProcess[str],
    passed_tests: set[str],
) -> None:
    assert name in passed_tests, (
        f"Swift test {name} did not pass:\n"
        f"{swift_run.stdout[-4000:]}\n{swift_run.stderr[-4000:]}"
    )
