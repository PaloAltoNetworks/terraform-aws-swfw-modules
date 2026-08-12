# ASG Lambda tests

Unit tests for `../scripts/lambda.py`, the Lambda that handles ASG launch and
terminate lifecycle actions.

These live outside `../scripts` on purpose: `data.archive_file.this` in `main.tf`
zips `source_dir = ${path.module}/scripts` wholesale, so anything placed there
ships inside the deployed Lambda payload.

## Running

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r modules/asg/tests/requirements-dev.txt
pytest modules/asg/tests/
```

The Lambda runs on `python3.11`. On Python 3.12 and newer, `pan-os-python==1.11.0`
imports `distutils`, which was removed from the standard library - install
`setuptools` in the virtualenv to restore the shim.
