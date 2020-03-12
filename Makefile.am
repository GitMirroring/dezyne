# Dezyne --- Dezyne command line tools
#
# Copyright © 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
#
# This file is part of Dezyne.
#
# Dezyne is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Dezyne is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
#
# Commentary:
#
# Code:

ACLOCAL_AMFLAGS = -I build-aux

EXTRA_DIST =					\
 .dir-locals.el					\
 HACKING					\
 ROADMAP					\
 autogen.sh					\
 build-aux/git-version-gen			\
 build-aux/gitlog-to-changelog			\
 guix.scm					\
 guix/gnu/packages/dezyne.scm

dist_lisp_DATA = emacs/dzn-mode.el

exampledir = $(docdir)

# Modules and scripts
#####################

do_subst = sed						\
  -e 's,[@]GUILE[@],$(GUILE),g'				\
  -e 's,[@]prefix[@],$(prefix),g'			\
  -e 's,[@]bindir[@],$(bindir),g'			\
  -e 's,[@]datadir[@],$(datadir),g'			\
  -e 's,[@]datarootdir[@],$(datarootdir),g'		\
  -e 's,[@]pkgdatadir[@],$(pkgdatadir),g'		\
  -e 's,[@]guilemoduledir[@],$(guilemoduledir),g'	\
  -e 's,[@]guileobjectdir[@],$(guileobjectdir),g'	\
  -e 's,[@]languages[@],$(languages),g'			\
  -e 's,[@]PACKAGE[@],$(PACKAGE),g'			\
  -e 's,[@]PACKAGE_VERSION[@],$(PACKAGE_VERSION),g'	\
  -e 's,[@]VERSION_MAJOR[@],$(VERSION_MAJOR),g'		\
  -e 's,[@]VERSION_MINOR[@],$(VERSION_MINOR),g'		\
  -e 's,[@]VERSION_PATCH[@],$(VERSION_PATCH),g'

AM_V_SED = $(AM_V_SED_@AM_V@)
AM_V_SED_ = $(AM_V_SED_@AM_DEFAULT_V@)
AM_V_SED_0 = @echo "  SED" $@;

bin/%: bin/%.in Makefile
	$(AM_V_SED)$(do_subst) < $< > $@
	@chmod a+x $@

dzn/%: dzn/%.in Makefile
	$(AM_V_SED)$(do_subst) < $< > $@

BUILT_SOURCES =

bin_SCRIPTS =					\
  bin/dzn

EXTRA_DIST +=					\
 bin/dzn.in

dist_noinst_DATA =
ALL_GO =
include dzn/local.mk
include gash/local.mk
include dzn/parse/local.mk
include dzn/peg/local.mk
include dzn/commands/local.mk
include runtime/local.mk
include dzn/verify/local.mk
include dzn/templates/local.mk

GUILEC_FLAGS = -Warity-mismatch -Wformat --load-path=$(abs_srcdir)

AM_V_GUILEC = $(AM_V_GUILEC_@AM_V@)
AM_V_GUILEC_ = $(AM_V_GUILEC_@AM_DEFAULT_V@)
AM_V_GUILEC_0 = @echo "  GUILEC" $@;

.scm.go:
	$(AM_V_GUILEC)GUILE_AUTO_COMPILE=0				\
	LTDL_LIBRARY_PATH=$(abs_builddir)/.libs				\
	$(GUILE_TOOLS) compile --target="$(host)" $(GUILEC_FLAGS)	\
	-o "$@" "$<"

CLEANFILES =					\
 $(BUILT_SOURCES)				\
 $(ALL_GO)

all-go: $(ALL_GO)
clean-go:
	rm -f $(ALL_GO)

# Tests
#######

include test/all/local.mk   # FULL_TESTS and XFAIL_TESTS
include test/dzn/local.mk
include test/lib/local.mk

TEST_EXTENSIONS = .scm
LOG_COMPILER = $(top_builddir)/pre-inst-env run
SCM_LOG_COMPILER = $(top_builddir)/pre-inst-env $(GUILE)
AM_SCM_LOG_FLAGS = --no-auto-compile

TESTS = $(UNIT_TESTS) $(FULL_TESTS)
EXTRA_DIST += $(TESTS)

# Documentation
###############

info_TEXINFOS = doc/dezyne.texi

dezyne_TEXINFOS = doc/fdl-1.3.texi

EXTRA_DIST +=					\
  $(dezyne_TEXINFOS)

EXTRA_DIST +=						\
 doc/semantics/direct_in.dzn				\
 doc/semantics/direct_multiple_out1.dzn			\
 doc/semantics/direct_multiple_out2.dzn			\
 doc/semantics/direct_out.dzn				\
 doc/semantics/external_multiple_out.dzn		\
 doc/semantics/indirect_blocking_multiple_out.dzn	\
 doc/semantics/indirect_blocking_out.dzn		\
 doc/semantics/indirect_multiple_out1.dzn		\
 doc/semantics/indirect_multiple_out2.dzn		\
 doc/semantics/indirect_multiple_out3.dzn		\
 doc/semantics/indirect_out.dzn

dist_info_images_DATA =					\
 doc/images/direct_in.png				\
 doc/images/direct_multiple_out1.png			\
 doc/images/direct_multiple_out2.png			\
 doc/images/direct_out.png				\
 doc/images/external_multiple_out.png			\
 doc/images/indirect_blocking_multiple_external_out.png	\
 doc/images/indirect_blocking_out.png			\
 doc/images/indirect_multiple_out1.png			\
 doc/images/indirect_multiple_out2.png			\
 doc/images/indirect_multiple_out3.png			\
 doc/images/indirect_out.png

info_imagesdir = $(infodir)/images
EXTRA_DIST += $(info_image_DATA)

dist_man_MANS =					\
 doc/dzn.1					\
 doc/dzn-cat.1					\
 doc/dzn-code.1					\
 doc/dzn-hello.1				\
 doc/dzn-lts.1					\
 doc/dzn-ls.1					\
 doc/dzn-parse.1				\
 doc/dzn-traces.1				\
 doc/dzn-trace.1				\
 doc/dzn-verify.1

doc/dzn.1: bin/dzn Makefile $(ALL_GO)
	./pre-inst-env help2man --output=$@ $<

doc/dzn-%.1: bin/dzn Makefile $(ALL_GO)
	./pre-inst-env help2man --output=$@ --version-string=$(PACKAGE_VERSION) "$< $*"

html: doc/html/index.html

doc/html/index.html: ${srcdest}doc/dezyne.texi doc/version.texi $(WEB_IMAGES)
	mkdir -p $(@D)/html_node
	$(MAKEINFO) --html -o $(@D)/html_node -I ${srcdest}doc -I doc $<
	$(MAKEINFO) --no-split --html -o $(@D)/dezyne.html -I ${srcdest}doc -I doc $<

# Distribution
##############

# Release process
#  0. Prepare for release
#     - fix all tests, or add failing tests to XFAIL_TESTS
#     - doc: Release update (NEWS, etc.)
#     - git clean -fdx
#     - ./autogen.sh; ./configure; make
#  1. make tag PACKAGE_VERSION=2.10.0
#  2. make sign-dist
#  3. make release
#  4. test guix package build, binary packs (see pack.git)
#     GUIX_PACKAGE_PATH=guix build dezyne
#     make linux
#     make mingw
#  5. Create announcement
#       make gen-announce PACKAGE_VERSION=2.10.0
#       Update and commit doc/announce/ANNOUNCE-2.10.0
#  6. Create blog post
#       cp doc/announce/ANNOUNCE-2.10.0 ~/src/web/dezyne.org/posts/announce-2.10.0.md
#  7. Send mail to
#     guile-user@gnu.org
#     mcrl2-users@listserver.tue.nl
#     guix formal verification interest group (guix-devel@gnu.org?)
#     ...

# Reproducible tarball
# Be friendly to Debian; avoid using EPOCH
GZIP_ENV = --no-name
am__tar = $${TAR-tar} \
 --sort=name \
 --mode=go=rX,u+rw,a-s \
 --mtime=@$$(cat "$$tardir"/.tarball-timestamp) \
 --owner=0 --group=0 --numeric-owner \
 -cf - \
 "$$tardir"

tag:
	git tag -s v$(PACKAGE_VERSION) -m "$(PACKAGE_NAME) $(PACKAGE_VERSION)."

dist-hook: gen-ChangeLog
	echo $(VERSION) > $(distdir)/.tarball-version
	git ls-tree -r --name-only HEAD > $(distdir)/.tarball-manifest
	git show HEAD --format=%ct --no-patch > $(distdir)/.tarball-timestamp
	rm -rf $(distdir)/test/all/*/out

# FIXME: this will only work after we switch to source tarball
# distribution and url-feth
release: update-hash
	git commit -m 'guix: Update hash.'					\
		-m '* guix/gnu/packages/dezyne.scm (dezyne): Update hash.'	\
		guix/gnu/packages/dezyne.scm

GPG_KEY_ID:=1A858392E331EAFDB8C27FFBF3C1A0D9C1D65273
GEN_ANNOUNCE=$(GNULIB)/build-aux/announce-gen
GNULIB=$(HOME)/src/gnulib
gen-announce:
	$(GEN_ANNOUNCE)						\
	    --release-type=beta					\
	    --package-name=dezyne				\
	    --previous-version='2.9.1'				\
            --current-version=$(PACKAGE_VERSION)		\
	    --gpg-key-id=$(GPG_KEY_ID)				\
	    --url-directory=https://dezyne.org/download/dezyne	\
	    --news=NEWS						\
            > doc/announce/ANNOUNCE-$(PACKAGE_VERSION)

if have_guix
update-hash: $(DIST_ARCHIVES)
	$(GUIX) download file://$(PWD)/$<
	sed -i \
		-e 's,base32 #!dezyne!# "[^"]*"),base32 #!dezyne!# "$(shell $(GUIX) hash $<)"),' \
		-e 's,version #!dezyne!# "[^"]*"),version #!dezyne!# "$(PACKAGE_VERSION)"),' \
	guix/gnu/packages/dezyne.scm
else
$(warning update-hash: no Guix)
endif

.PHONY: gen-ChangeLog
gen-ChangeLog $(distdir)/ChangeLog: config.status
	$(AM_V_GEN)if test -e .git; then		\
	  $(top_srcdir)/build-aux/gitlog-to-changelog	\
	    > $(distdir)/cl-t;				\
	  rm -f $(distdir)/ChangeLog;			\
	  mv $(distdir)/cl-t $(distdir)/ChangeLog;	\
	fi

sign-dist: dist
	gpg -a --output $(distdir).tar.gz.sig --detach-sig $(distdir).tar.gz

distcheck-hook:
	set -e;                                 \
	manifest=$(distdir)/.tarball-manifest;  \
	test -f "$$manifest";                   \
	for x in `cat "$$manifest"`;            \
	do                                      \
	    if ! test -f $(distdir)/"$$x"       \
                && ! test "$$x" = .gitignore;   \
	    then                                \
	        echo "Missing: $$x";            \
	        exit 1;                         \
	    fi;                                 \
	done

define C_VERSION_COMMENT
//version: $(PACKAGE_VERSION)
endef

define LISP_VERSION_COMMENT
;;;version: $(PACKAGE_VERSION)
endef

install-data-hook:
if have_cxx11
	echo "$(C_VERSION_COMMENT)" | tee -a $$(find $(DESTDIR)$(pkgdatadir)/runtime/c++ -type f)
endif
if have_javascript
	echo "$(C_VERSION_COMMENT)" | tee -a $$(find $(DESTDIR)$(pkgdatadir)/runtime/javascript -type f)
endif
if have_scheme
	echo "$(LISP_VERSION_COMMENT)" | tee -a $$(find $(DESTDIR)$(pkgdatadir)/runtime/scheme -type f)
endif
