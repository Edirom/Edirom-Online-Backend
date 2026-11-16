# Regression Tests

This directory contains regression tests for the Edirom Online Backend API endpoints.

## Concept

The regression tests work by comparing API responses from a test backend against expected results stored in the `expected-results/` directory. The test script:

1. Makes HTTP requests to various API endpoints
2. Compares the responses against pre-stored expected results
3. Reports any differences (regressions)

Each endpoint response is stored as a file named with its MD5 hash to avoid filename conflicts.


## Quick Guide

### Run Tests

Run regression tests against your test backend:

```bash
docker build -t edirom-online-backend:test .
ant docker-run-test-image -Dtest.image=edirom-online-backend:test
ant regression-tests
ant test-cleanup
```

This will compare all defined endpointsresponses with expected results and report any differences

### Update Expected Results

When you've intentionally changed the API behavior and you need to update the baseline for future tests. Run this:

```bash
docker build -t edirom-online-backend:test .
ant docker-run-test-image -Dtest.image=edirom-online-backend:test
ant regression-tests-reset
ant test-cleanup
```

You will then need to submit the updated tests results together with your PR.

## Adding New Tests

To add new endpoints to test:

1. Edit `regression-test.sh`
2. Add the endpoint to the `ENDPOINTS` array (line 29)
3. Run `./regression-test.sh reset` to generate the expected result

## Normalization

The script automatically normalizes responses to avoid false positives:
- Replaces host and port numbers (`localhost:8080` → `xxxx`)
- Replaces dynamic IDs (`PD123N` → `PDxxxN`)