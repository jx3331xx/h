# Import tree-wide shared Makefile behavior and libraries
include ../shared.mak

# make and install sample templates
INSTALL ?= install
TAR ?= tar
RM ?= rm -f
prefix ?= $(HOME)
template_instdir ?= $(prefix)/share/git-core/templates
# DESTDIR=

ifndef SHELL_PATH
	SHELL_PATH = /bin/sh
endif
ifndef PERL_PATH
	PERL_PATH = perl
endif

all: boilerplates.made custom

# Put templates that can be copied straight from the source
# in a file direc--tory--file in the source.  They will be
# just copied to the destination.

bpsrc = $(filter-out %~,$(wildcard *--*))
boilerplates.made : $(bpsrc)
	$(QUIET)umask 022 && ls *--* 2>/dev/null | \
	while read boilerplate; \
	do \
		case "$$boilerplate" in *~) continue ;; esac && \
		dst=`echo "$$boilerplate" | sed -e 's|^this|.|;s|--|/|g'` && \
		dir=`expr "$$dst" : '\(.*\)/'` && \
		mkdir -p blt/$$dir && \
		case "$$boilerplate" in \
		*--) continue;; \
		esac && \
		sed -e '1s|#!.*/sh|#!$(SHELL_PATH_SQ)|' \
		    -e 's|@SHELL_PATH@|$(SHELL_PATH_SQ)|' \
		    -e 's|@PERL_PATH@|$(PERL_PATH_SQ)|g' $$boilerplate > \
			blt/$$dst && \
		if test -x "$$boilerplate"; then rx=rx; else rx=r; fi && \
		chmod a+$$rx "blt/$$dst" || exit; \
	done && \
	date >$@

# If you need build-tailored templates, build them into blt/
# directory yourself here.
custom:
	$(QUIET): no custom templates yet

clean:
	$(RM) -r blt boilerplates.made

install: all
	$(INSTALL) -d -m755 $(call shellquote,$(DESTDIR)$(template_instdir))
	(cd blt && $(TAR) cf - .) | \
	(cd $(call shellquote,$(DESTDIR)$(template_instdir)) && umask 022 && $(TAR) xof -)
