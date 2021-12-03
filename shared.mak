### Remove GNU make implicit rules

## This speeds things up since we don't need to look for and stat() a
## "foo.c,v" every time a rule referring to "foo.c" is in play. See
## "make -p -f/dev/null | grep ^%::'".
%:: %,v
%:: RCS/%,v
%:: RCS/%
%:: s.%
%:: SCCS/s.%

## Likewise delete default $(SUFFIXES). See:
##
##     info make --index-search=.DELETE_ON_ERROR
.SUFFIXES:

### Flags affecting all rules

# A GNU make extension since gmake 3.72 (released in late 1994) to
# remove the target of rules if commands in those rules fail. The
# default is to only do that if make itself receives a signal. Affects
# all targets, see:
#
#    info make --index-search=.DELETE_ON_ERROR
.DELETE_ON_ERROR:

### GNU Make version detection
# We don't care about "release" versions like the "90" in "3.99.90"
MAKE_VERSION_MAJOR = $(word 1,$(subst ., ,$(MAKE_VERSION)))
MAKE_VERSION_MINOR = $(word 2,$(subst ., ,$(MAKE_VERSION)))

# The oldest supported version of GNU make is 3-something. So "not v3"
# is a future-proof way to ask "is it modern?"
ifneq ($(MAKE_VERSION_MAJOR),3)
# $(file >[...]) and $(file >>[...]) is in 4.0...
MAKE_HAVE_FILE_WRITE = Need version 4.0 or later (released in late 2013)
# .. but we need 4.2 for $(file <[...])
ifneq ($(filter-out 0 1,$(MAKE_VERSION_MINOR)),)
MAKE_HAVE_FILE_READ = Need version 4.2 or later (released in mid-2016)
endif
endif

### Quoting helpers

## Quote a ' inside a '': FOO='$(call shq,$(BAR))'
shq = $(subst ','\'',$(1))

## Quote a ' and provide a '': FOO=$(call shq,$(BAR))
shellquote = '$(call shq,$(1))'

## Quote a " inside a ""
shdq = $(subst ",\",$(1))

## Quote ' for the shell, and embedded " for C: -DFOO=$(call shelldquote,$(BAR))
shelldquote = '"$(call shdq,$(call shq,$(1)))"'

### Global variables

## comma, empty, space: handy variables as these tokens are either
## special or can be hard to spot among other Makefile syntax.
comma = ,
empty =
space = $(empty) $(empty)

## wspfx: the whitespace prefix padding for $(QUIET...) and similarly
## aligned output.
wspfx = $(space)$(space)$(space)
wspfx_sq = $(call shellquote,$(wspfx))

### Quieting
## common
QUIET_SUBDIR0  = +$(MAKE) -C # space to separate -C and subdir
QUIET_SUBDIR1  =

ifneq ($(findstring w,$(MAKEFLAGS)),w)
PRINT_DIR = --no-print-directory
else # "make -w"
NO_SUBDIR = :
endif

ifneq ($(findstring s,$(MAKEFLAGS)),s)
ifndef V
## common
	QUIET_SUBDIR0  = +@subdir=
	QUIET_SUBDIR1  = ;$(NO_SUBDIR) echo $(wspfx_sq) SUBDIR $$subdir; \
			 $(MAKE) $(PRINT_DIR) -C $$subdir

	QUIET          = @
	QUIET_GEN      = @echo $(wspfx_sq) GEN $@;

	QUIET_MKDIR_P_PARENT  = @echo $(wspfx_sq) MKDIR -p $(@D);

## Used in "Makefile"
	QUIET_CC       = @echo $(wspfx_sq) CC $@;
	QUIET_AR       = @echo $(wspfx_sq) AR $@;
	QUIET_LINK     = @echo $(wspfx_sq) LINK $@;
	QUIET_BUILT_IN = @echo $(wspfx_sq) BUILTIN $@;
	QUIET_LNCP     = @echo $(wspfx_sq) LN/CP $@;
	QUIET_XGETTEXT = @echo $(wspfx_sq) XGETTEXT $@;
	QUIET_MSGFMT   = @echo $(wspfx_sq) MSGFMT $@;
	QUIET_GCOV     = @echo $(wspfx_sq) GCOV $@;
	QUIET_SP       = @echo $(wspfx_sq) SP $<;
	QUIET_HDR      = @echo $(wspfx_sq) HDR $(<:hcc=h);
	QUIET_RC       = @echo $(wspfx_sq) RC $@;
	QUIET_SPATCH   = @echo $(wspfx_sq) SPATCH $<;

## Used in "Documentation/Makefile"
	QUIET_ASCIIDOC	= @echo $(wspfx_sq) ASCIIDOC $@;
	QUIET_XMLTO	= @echo $(wspfx_sq) XMLTO $@;
	QUIET_DB2TEXI	= @echo $(wspfx_sq) DB2TEXI $@;
	QUIET_MAKEINFO	= @echo $(wspfx_sq) MAKEINFO $@;
	QUIET_DBLATEX	= @echo $(wspfx_sq) DBLATEX $@;
	QUIET_XSLTPROC	= @echo $(wspfx_sq) XSLTPROC $@;
	QUIET_GEN	= @echo $(wspfx_sq) GEN $@;
	QUIET_STDERR	= 2> /dev/null

	QUIET_LINT_GITLINK	= @echo $(wspfx_sq) LINT GITLINK $<;
	QUIET_LINT_MANSEC	= @echo $(wspfx_sq) LINT MAN SEC $<;
	QUIET_LINT_MANEND	= @echo $(wspfx_sq) LINT MAN END $<;

	export V
endif
endif

## Helpers
define mkdir_p_parent_template
$(if $(wildcard $(@D)),,$(QUIET_MKDIR_P_PARENT)$(shell mkdir -p $(@D)))
endef

### Templates

## Template for making a GIT-SOMETHING, which changes if a
## TRACK_SOMETHING variable changes.
##
## This is the slower version used on GNU make <4.2.
ifndef MAKE_HAVE_FILE_READ

define TRACK_template
.PHONY: FORCE
$(1): FORCE
	@FLAGS='$$($(2))'; \
	if ! test -f $(1) ; then \
		echo $(wspfx_sq) "$(1) PARAMETERS (new)"; \
		echo "$$$$FLAGS" >$(1); \
	elif test x"$$$$FLAGS" != x"`cat $(1) 2>/dev/null`" ; then \
		echo $(wspfx_sq) "$(1) PARAMETERS (changed)"; \
		echo "$$$$FLAGS" >$(1); \
	fi
endef

endif # !MAKE_HAVE_FILE_READ

## A TRACK_template template compatible with the one above. Uses
## features of GNU make >=4.2 to avoid shelling out for this "hot"
## "FORCE" logic.
##
## Since version >=4.2 can do both "I" and "O" in I/O with using
## $(file <)/$(file >) we read the GIT-SOMETHING file into a variable
## with the former, and if it's different from our expected value
## write it out with the latter.
ifdef MAKE_HAVE_FILE_READ

define TRACK_template_eval
$(1)_WRITE =
$(1)_EXISTS = $(wildcard $(1))
ifeq ($$($(1)_EXISTS),)
$(1)_WRITE = new
else
$(1)_CONTENT = $(file <$(1))
ifeq ($$($(1)_CONTENT),$($(2)))
$(1)_WRITE = same
else
$(1)_WRITE = changed
endif
endif
ifneq ($$($(1)_WRITE),same)
$$(info $$(wspfx) $(1) parameters ($$($(1)_WRITE)))
$$(file >$(1),$($(2)))
endif
endef # TRACK_template_eval

define TRACK_template
$(1):
	$$(eval $$(call TRACK_template_eval,$(1),$(2)))
endef

endif # MAKE_HAVE_FILE_READ
