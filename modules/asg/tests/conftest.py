"""Test configuration for the ASG lifecycle Lambda.

The Lambda source lives in `../scripts` and is packaged by `archive_file`
(source_dir = ${path.module}/scripts), so tests are kept outside that
directory to keep them out of the deployed payload.

`lambda.py` cannot be imported by name - `lambda` is a Python keyword - so it is
loaded from its path and registered under the alias `lambda_function_under_test`.
"""
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
from sys import modules

MODULE_ALIAS = "lambda_function_under_test"
LAMBDA_SOURCE = Path(__file__).resolve().parent.parent / "scripts" / "lambda.py"

_spec = spec_from_file_location(MODULE_ALIAS, LAMBDA_SOURCE)
_module = module_from_spec(_spec)
modules[MODULE_ALIAS] = _module
_spec.loader.exec_module(_module)
