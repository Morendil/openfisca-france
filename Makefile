all: test

uninstall:
	pip freeze | grep -v "^-e" | xargs pip uninstall -y

clean:
	rm -rf build dist
	find . -name '*.pyc' -exec rm \{\} \;

deps:
	pip install --upgrade pip twine wheel
	pip install openfisca-core[web-api]

install: deps
	@# Install OpenFisca-France for development.
	@# `make install` installs the editable version of OpenFisca-France.
	@# This allows contributors to test as they code.
	pip install --editable --upgrade .[dev]

build: clean deps
	@# Install OpenFisca-France for deployment and publishing.
	@# `make build` allows us to be be sure tests are run against the packaged version
	@# of OpenFisca-France, the same we put in the hands of users and reusers.
	python setup.py bdist_wheel
	find dist -name "*.whl" -exec pip install --upgrade {}[dev] \;

check-no-prints:
	@test -z "`git grep -w print openfisca_france/model`"

check-syntax-errors:
	python -m compileall -q .

check-style:
	@# Do not analyse .gitignored files.
	@# `make` needs `$$` to output `$`. Ref: http://stackoverflow.com/questions/2382764.
	flake8 `git ls-files | grep "\.py$$"`

format-style:
	@# Do not analyse .gitignored files.
	@# `make` needs `$$` to output `$`. Ref: http://stackoverflow.com/questions/2382764.
	autopep8 `git ls-files | grep "\.py$$"`

test: clean check-syntax-errors check-no-prints check-style
	@# Launch tests from openfisca_france/tests directory (and not .) because TaxBenefitSystem must be initialized
	@# before parsing source files containing formulas.
	nosetests tests --exe --with-doctest
	openfisca-run-test --country-package openfisca_france tests

performance:
	python openfisca_france/scripts/performance_tests/test_tests.py
