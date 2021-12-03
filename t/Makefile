# Import tree-wide shared Makefile behavior and libraries
include ../shared.mak

# Run tests
#
# Copyright (c) 2005 Junio C Hamano
#

-include ../config.mak.autogen
-include ../config.mak

#GIT_TEST_OPTS = --verbose --debug
SHELL_PATH ?= $(SHELL)
TEST_SHELL_PATH ?= $(SHELL_PATH)
PERL_PATH ?= /usr/bin/perl
TAR ?= $(TAR)
RM ?= rm -f
PROVE ?= prove
DEFAULT_TEST_TARGET ?= test
TEST_LINT ?= test-lint

ifdef TEST_OUTPUT_DIRECTORY
TEST_RESULTS_DIRECTORY = $(TEST_OUTPUT_DIRECTORY)/test-results
CHAINLINTTMP = $(TEST_OUTPUT_DIRECTORY)/chainlinttmp
else
TEST_RESULTS_DIRECTORY = test-results
CHAINLINTTMP = chainlinttmp
endif

T = $(sort $(wildcard t[0-9][0-9][0-9][0-9]-*.sh))
TGITWEB = $(sort $(wildcard t95[0-9][0-9]-*.sh))
THELPERS = $(sort $(filter-out $(T),$(wildcard *.sh)))
TPERF = $(sort $(wildcard perf/p[0-9][0-9][0-9][0-9]-*.sh))
CHAINLINTTESTS = $(sort $(patsubst chainlint/%.test,%,$(wildcard chainlint/*.test)))
CHAINLINT = sed -f chainlint.sed

all: $(DEFAULT_TEST_TARGET)

test: pre-clean check-chainlint $(TEST_LINT)
	$(MAKE) aggregate-results-and-cleanup

failed:
	@failed=$$(cd $(call shellquote,$(TEST_RESULTS_DIRECTORY)) && \
		grep -l '^failed [1-9]' *.counts | \
		sed -n 's/\.counts$$/.sh/p') && \
	test -z "$$failed" || $(MAKE) $$failed

prove: pre-clean check-chainlint $(TEST_LINT)
	@echo "*** prove ***"; $(PROVE) --exec $(call shellquote,$(SHELL_PATH)) $(GIT_PROVE_OPTS) $(T) :: $(GIT_TEST_OPTS)
	$(MAKE) clean-except-prove-cache

$(T):
	@echo "*** $@ ***"; $(call shellquote,$(SHELL_PATH)) $@ $(GIT_TEST_OPTS)

pre-clean:
	$(RM) -r $(call shellquote,$(TEST_RESULTS_DIRECTORY))

clean-except-prove-cache: clean-chainlint
	$(RM) -r 'trash directory'.* $(call shellquote,$(TEST_RESULTS_DIRECTORY))
	$(RM) -r valgrind/bin

clean: clean-except-prove-cache
	$(RM) .prove

clean-chainlint:
	$(RM) -r $(call shellquote,$(CHAINLINTTMP))

check-chainlint:
	@mkdir -p $(call shellquote,$(CHAINLINTTMP)) && \
	err=0 && \
	for i in $(CHAINLINTTESTS); do \
		$(CHAINLINT) <chainlint/$$i.test | \
		sed -e '/^# LINT: /d' >$(call shellquote,$(CHAINLINTTMP))/$$i.actual && \
		diff -u chainlint/$$i.expect $(call shellquote,$(CHAINLINTTMP))/$$i.actual || err=1; \
	done && exit $$err

test-lint: test-lint-duplicates test-lint-executable test-lint-shell-syntax \
	test-lint-filenames

test-lint-duplicates:
	@dups=`echo $(T) $(TPERF) | tr ' ' '\n' | sed 's/-.*//' | sort | uniq -d` && \
		test -z "$$dups" || { \
		echo >&2 "duplicate test numbers:" $$dups; exit 1; }

test-lint-executable:
	@bad=`for i in $(T) $(TPERF); do test -x "$$i" || echo $$i; done` && \
		test -z "$$bad" || { \
		echo >&2 "non-executable tests:" $$bad; exit 1; }

test-lint-shell-syntax:
	@$(call shellquote,$(PERL_PATH)) check-non-portable-shell.pl $(T) $(THELPERS) $(TPERF)

test-lint-filenames:
	@# We do *not* pass a glob to ls-files but use grep instead, to catch
	@# non-ASCII characters (which are quoted within double-quotes)
	@bad="$$(git -c core.quotepath=true ls-files 2>/dev/null | \
			grep '["*:<>?\\|]')"; \
		test -z "$$bad" || { \
		echo >&2 "non-portable file name(s): $$bad"; exit 1; }

aggregate-results-and-cleanup: $(T)
	$(MAKE) aggregate-results
	$(MAKE) clean

aggregate-results:
	for f in $(call shellquote,$(TEST_RESULTS_DIRECTORY))/t*-*.counts; do \
		echo "$$f"; \
	done | $(call shellquote,$(SHELL_PATH)) ./aggregate-results.sh

gitweb-test:
	$(MAKE) $(TGITWEB)

valgrind:
	$(MAKE) GIT_TEST_OPTS="$(GIT_TEST_OPTS) --valgrind"

perf:
	$(MAKE) -C perf/ all

.PHONY: pre-clean $(T) aggregate-results clean valgrind perf check-chainlint clean-chainlint
