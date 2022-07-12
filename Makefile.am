# Dezyne --- Dezyne command line tools
#
# Copyright © 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2019 Timothy Sample <samplet@ngyro.com>
# Copyright © 2020, 2021 Rutger van Beusekom <rutger@dezyne.org>
# Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
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
 .reuse/dep5					\
 COPYING.AGPL					\
 COPYING.CC0					\
 COPYING.LESSER					\
 HACKING					\
 ROADMAP					\
 autogen.sh					\
 build-aux/git-version-gen			\
 build-aux/gitlog-to-changelog			\
 build-aux/update-semantics.sh			\
 guix.scm					\
 guix/pack/dezyne.scm

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
  -e 's,[@]PACKAGE_NAME[@],$(PACKAGE_NAME),g'		\
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
 bin/dzn.in					\
 test/bin/semantics.sh

dist_noinst_DATA =
ALL_GO =
include dzn/peg/local.mk
include dzn/parse/local.mk
include dzn/code/local.mk
include dzn/vm/local.mk
include dzn/local.mk
include dzn/commands/local.mk
include runtime/local.mk
include runtime/scheme/dzn/local.mk
include dzn/verify/local.mk
include dzn/templates/local.mk
include emacs/local.mk

GUILEC_FLAGS =					\
 -Warity-mismatch				\
 -Wformat					\
 --load-path=$(abs_top_srcdir)			\
 --load-path=$(abs_top_srcdir)/runtime/scheme

AM_V_GUILEC = $(AM_V_GUILEC_@AM_V@)
AM_V_GUILEC_ = $(AM_V_GUILEC_@AM_DEFAULT_V@)
AM_V_GUILEC_0 = @echo "  GUILEC" $@;

%.go:	%.scm
	$(AM_V_GUILEC)GUILE_AUTO_COMPILE=0				\
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
include test/language/local.mk
include test/lts/local.mk

TEST_EXTENSIONS = .scm
LOG_COMPILER = $(top_builddir)/pre-inst-env run $(RUN_FLAGS)
SCM_LOG_COMPILER = $(top_builddir)/pre-inst-env $(GUILE)
AM_SCM_LOG_FLAGS = --no-auto-compile

TESTS = $(UNIT_TESTS) $(FULL_TESTS)
EXTRA_DIST += $(TESTS)

# Documentation
###############

info_TEXINFOS =					\
 doc/dezyne.texi

dezyne_TEXINFOS = doc/fdl-1.3.texi

EXTRA_DIST +=					\
  $(dezyne_TEXINFOS)

include doc/examples/local.mk
include doc/images/local.mk
include doc/parse/local.mk
include doc/semantics/local.mk

update-doc: $(dezyne_TEXINFOS)

doc/parse/%.texi: doc/parse/%.dzn $(ALL_GO)
	$(AM_V_GEN)(cd $(<D)					\
	    && ../../pre-inst-env dzn parse $(<F);:) 2>&1	\
	    | fmt --split-only --width=73 --goal=73		\
	    | sed '/^.*[.]dzn:/! s,^,    ,'			\
	    > $@

info_imagesdir = $(infodir)/images
EXTRA_DIST += $(info_image_DATA)

dist_man_MANS =					\
 doc/dzn.1					\
 doc/dzn-code.1					\
 doc/dzn-graph.1				\
 doc/dzn-hello.1				\
 doc/dzn-language.1				\
 doc/dzn-lts.1					\
 doc/dzn-parse.1				\
 doc/dzn-simulate.1				\
 doc/dzn-traces.1				\
 doc/dzn-trace.1				\
 doc/dzn-verify.1

doc/dzn.1:
	./pre-inst-env help2man --output=$@ bin/dzn

doc/dzn-%.1:
	./pre-inst-env help2man --output=$@ --version-string=$(PACKAGE_VERSION) "bin/dzn $*"

MAKEINFO_HTML_OPTIONS =									\
 --css-ref=https://www.gnu.org/software/gnulib/manual.css				\
 -c EXTRA_HEAD='<meta name="viewport" content="width=device-width, initial-scale=1" />'

# Ask for warnings about cross-referenced manuals that are not listed in
# htmlxref.cnf.
EXTRA_DIST += .texinfo/htmlxref.cnf
AM_MAKEINFOHTMLFLAGS = --set-customization-variable CHECK_HTMLXREF=true

html: html-manual
html-manual: doc/html/dezyne/index.html

doc/html/dezyne/index.html: ${srcdest}doc/dezyne.texi doc/version.texi $(WEB_IMAGES)
	mkdir -p $(@D)/html_node
	$(MAKEINFO) --html $(MAKEINFO_HTML_OPTIONS) -o $(@D)/html_node -I ${srcdest}doc -I doc $<
	$(MAKEINFO) --no-split --html $(MAKEINFO_HTML_OPTIONS) -o $(@D)/dezyne.html -I ${srcdest}doc -I doc $<

SITE = /srv/dezyne.org/site/dezyne
publish: html pdf
	rsync -P -v . $(SITE)/
	rsync -P -v . $(SITE)/manual/
	rsync -P -rvz --delete doc/html/ $(SITE)/manual/
	rsync -P -rvz --delete doc/images $(SITE)/manual/dezyne/
	rsync -P -rvz --delete doc/images $(SITE)/manual/dezyne/html_node/
	rsync -P -rvz doc/dezyne.pdf $(SITE)/manual/

DEVEL_SITE = /srv/dezyne.org/site/devel
publish-devel: html pdf
	$(MAKE) publish SITE=$(DEVEL_SITE)

LOCAL_SITE = $(HOME)/src/web/dezyne.org/site/dezyne
publish-local: html pdf
	$(MAKE) publish SITE=$(LOCAL_SITE)

LOCAL_DEVEL_SITE = $(HOME)/src/web/dezyne.org/site/devel
publish-local-devel: html pdf
	$(MAKE) publish SITE=$(LOCAL_DEVEL_SITE)

# Generate 'version.texi' reproducibly using metadata from Git rather
# than using metadata from the filesystem.
override $(srcdir)/doc/version.texi:
	$(AM_V_GEN)set -e						\
	LC_ALL=C; export LC_ALL;					\
	TZ=UTC0; export TZ;						\
	timestamp=$$({ git log --pretty=format:%ct -- doc/dezyne.texi	\
		       || date +%s -r doc/dezyne.texi; }		\
	                 | sort -n -r | head -n 1);			\
	dmy=$$(date --date="@$$timestamp" "+%-d %B %Y");		\
	my=$$(date --date="@$$timestamp" "+%B %Y");			\
	{ echo "@set UPDATED $$dmy";					\
	  echo "@set UPDATED-MONTH $$my";				\
	  echo "@set EDITION $(VERSION)";				\
	  echo "@set VERSION $(VERSION)"; } > $@-t;			\
	mv $@-t $@

# Distribution
##############

# Release process
#  0. Prepare for release
#     - Fix all tests, or add failing tests to XFAIL_TESTS
#     - doc: Release update (NEWS, etc.)
#     - Generate announcement
#       make gen-announce PACKAGE_VERSION=2.10.0
#     - Update and commit doc/announce/ANNOUNCE-2.10.0
#  1. Tag for release
#     make tag PACKAGE_VERSION=2.10.0
#     ./autogen.sh
#  2. Create signed tarball
#     make sign-dist
#  3. Update Guix package description
#     make release
#  4. test guix package build, binary packs (see pack.git README)
#     git --git-dir ~/src/dezyne/release/.git format-patch -1
#     git am 0001-guix-dezyne-Update-to-2.10.0.patch
#     make tag PACKAGE_VERSION=2.10.0
#     ./autogen.sh
#     make dezyne
#  5. Finish announcement
#     - make sum-announce
#     - doc: Post-release update.
#     - build-aux/GNUMakefile.in: gen-announce: update previous-version
#  6. Create blog post
#     cp doc/announce/ANNOUNCE-2.10.0 ~/src/web/dezyne.org/posts/announce-2.10.0.md
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
	@touch $(distdir)/.git
	@echo Removing any test output
	@rm -rf $(distdir)/test/all/*/out

release: update-hash
	git commit -m 'guix: dezyne: Update to $(PACKAGE_VERSION).'		\
	    -m '* guix/pack/dezyne.scm (dezyne): Update to $(PACKAGE_VERSION).'	\
	    guix/pack/dezyne.scm

GPG_KEY_ID=1A858392E331EAFDB8C27FFBF3C1A0D9C1D65273
GEN_ANNOUNCE=$(GNULIB)/build-aux/announce-gen
GNULIB=$(HOME)/src/gnulib
gen-announce:
# Allow generating DRAFT announcement without release tarballs.
	sed -e 's,or die "[$$]ME: none,or print STDERR "$$ME: none,'	\
	    -e 's,or exit 1;,;,'					\
	    $(GEN_ANNOUNCE)						\
	    > build-aux/announce-gen
	chmod +x build-aux/announce-gen
	build-aux/announce-gen					\
	    --release-type=stable				\
	    --package-name=$(PACKAGE)				\
	    --previous-version='2.15.2'				\
            --current-version=$(PACKAGE_VERSION)		\
	    --gpg-key-id=$(GPG_KEY_ID)				\
	    --url-directory=https://dezyne.org/download/dezyne	\
	    --news=NEWS						\
            > doc/announce/ANNOUNCE-$(PACKAGE_VERSION)

sum-announce:
	sed -ri																						\
	    -e "s,(^|  )xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  $(PACKAGE)-$(PACKAGE_VERSION).tar.gz,  $(shell sha256sum $(PACKAGE)-$(PACKAGE_VERSION).tar.gz),"	\
	    -e "s,(^|  )xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  $(PACKAGE)-$(PACKAGE_VERSION).tar.gz,  $(shell sha1sum $(PACKAGE)-$(PACKAGE_VERSION).tar.gz),"				\
	    -e "s,(^|  )xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  $(PACKAGE)-$(PACKAGE_VERSION).tar.gz,  $(shell md5sum $(PACKAGE)-$(PACKAGE_VERSION).tar.gz),"					\
	doc/announce/ANNOUNCE-$(PACKAGE_VERSION)

if have_guix
update-hash: $(DIST_ARCHIVES)
	$(GUIX) download file://$(PWD)/$<
	sed -i \
		-e 's,base32 #!dezyne!# "[^"]*"),base32 #!dezyne!# "$(shell $(GUIX) hash $<)"),' \
		-e 's,version #!dezyne!# "[^"]*"),version #!dezyne!# "$(PACKAGE_VERSION)"),' \
	guix/pack/dezyne.scm
else
$(warning update-hash: no Guix)
endif

.PHONY: gen-ChangeLog
gen-ChangeLog $(distdir)/ChangeLog: config.status
	$(AM_V_GEN)if test -e .git; then				\
	  { 								\
	    $(top_srcdir)/build-aux/gitlog-to-changelog			\
	    && echo							\
	    && sed -n -e '/^Copyright/,$$p' < $(top_srcdir)/ChangeLog;	\
	  } 								\
	    > $(distdir)/cl-t;						\
	  rm -f $(distdir)/ChangeLog;					\
	  mv $(distdir)/cl-t $(distdir)/ChangeLog;			\
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
if have_c99
	echo "$(C_VERSION_COMMENT)" | tee -a $$(find $(DESTDIR)$(pkgdatadir)/runtime/c -type f)
endif
if have_cs
	echo "$(C_VERSION_COMMENT)" | tee -a $$(find $(DESTDIR)$(pkgdatadir)/runtime/cs -type f)
endif
if have_cxx11
	echo "$(C_VERSION_COMMENT)" | tee -a $$(find $(DESTDIR)$(pkgdatadir)/runtime/c++ -type f)
endif
if have_cxx_exception_wrappers
	echo "$(C_VERSION_COMMENT)" | tee -a $$(find $(DESTDIR)$(pkgdatadir)/runtime/examples -type f)
endif
if have_javascript
	echo "$(C_VERSION_COMMENT)" | tee -a $$(find $(DESTDIR)$(pkgdatadir)/runtime/javascript -type f)
endif
if have_scheme
	echo "$(LISP_VERSION_COMMENT)" | tee -a $$(find $(DESTDIR) -name locator.scm -o -name pump.scm -o -name runtime.scm)
	touch -d@0 $$(find $(DESTDIR) -name locator.scm -o -name pump.scm -o -name runtime.scm)
endif

check-reuse:
	rm -rf LICENSES
	mkdir -p LICENSES LICENCES
	ln COPYING LICENSES/GPL-3.0-or-later.text
	ln COPYING.AGPL LICENSES/AGPL-3.0-or-later.text
	ln COPYING.CC0 LICENSES/CC0-1.0.text
	ln COPYING.LESSER LICENSES/LGPL-3.0-or-later.text
	ln doc/fdl-1.3.texi LICENSES/GFDL-1.3-no-invariants-or-later.text
	reuse lint
	rm -rf LICENSES
