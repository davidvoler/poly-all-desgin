import asyncio
import os
from datetime import datetime
from importlib import import_module
from pathlib import Path

import pytest
import yaml


CASES_FILE = Path(__file__).with_name("prompt_cases.yaml")
OUTPUT_FILE = os.environ.get("PROMPT_OUTPUT_FILE")


def _load_cases():
    with CASES_FILE.open(encoding="utf-8") as input_file:
        document = yaml.safe_load(input_file) or {}

    cases = document.get("runs", [])
    if not cases:
        raise ValueError(f"No runs found in {CASES_FILE}")
    return cases


def _input_comments():
    return [
        line
        for line in CASES_FILE.read_text(encoding="utf-8").splitlines()
        if line.lstrip().startswith("#")
    ]


def _output_file(kind):
    if OUTPUT_FILE:
        return Path(OUTPUT_FILE)
    timestamp = datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
    return CASES_FILE.parent / "results" / f"{kind}-{timestamp}.yaml"


def _write_results(results, output_file):
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with output_file.open("w", encoding="utf-8") as result_file:
        comments = "\n".join(_input_comments())
        if comments:
            result_file.write(f"{comments}\n\n")
        yaml.safe_dump(
            {"tests": results},
            result_file,
            sort_keys=False,
            allow_unicode=True,
        )


def _run_cases(include_results, output_file):
    results = []
    failures = []

    for case in _load_cases():
        result = {
            "test": {
                "target": case["target"],
                "params": case["args"],
            },
            "comments": case.get("comment", ""),
        }
        try:
            value = asyncio.run(_call_prompt_async(case["target"], case["args"]))
            if include_results:
                result["results"] = value.model_dump(mode="json")
            result["status"] = "success"
        except Exception as error:  # Keep earlier results when one run fails.
            if include_results:
                result["results"] = {"error": f"{type(error).__name__}: {error}"}
            result["status"] = "fail"
            failures.append(case["name"])
        results.append(result)
        _write_results(results, output_file)

    assert not failures, f"Prompt runs failed: {', '.join(failures)}"


@pytest.mark.prompt_live
def test_prompt_execution(request):
    if not request.config.getoption("--run-prompts"):
        pytest.skip("Pass --run-prompts to run basic prompt tests")
    _run_cases(include_results=False, output_file=_output_file("basic"))


@pytest.mark.prompt_live
def test_prompt_quality(request):
    if not request.config.getoption("--run-prompt-quality"):
        pytest.skip("Pass --run-prompt-quality to run quality prompt tests")
    _run_cases(include_results=True, output_file=_output_file("quality"))


async def _call_prompt_async(target, arguments):
    module_name, function_name = target.split(":", maxsplit=1)
    function = getattr(import_module(module_name), function_name)
    return await function(**arguments)
