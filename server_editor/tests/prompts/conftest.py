def pytest_addoption(parser):
    parser.addoption(
        "--run-prompts",
        action="store_true",
        default=False,
        help="Run basic live prompt tests and write status results to YAML.",
    )
    parser.addoption(
        "--run-prompt-quality",
        action="store_true",
        default=False,
        help="Run live prompt quality tests and write model output to YAML.",
    )