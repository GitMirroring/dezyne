# Dezyne --- Dezyne command line tools
#
# Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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
 autogen.sh					\
 build-aux/git-version-gen			\
 build-aux/gitlog-to-changelog			\
 guix.scm					\
 guix/gnu/packages/dzn.scm

exampledir = $(docdir)

# Modules and scripts
#####################

do_subst = sed						\
  -e 's,[@]GUILE[@],$(GUILE),g'				\
  -e 's,[@]prefix[@],$(prefix),g'			\
  -e 's,[@]exec_prefix[@],$(exec_prefix),g'		\
  -e 's,[@]bindir[@],$(bindir),g'			\
  -e 's,[@]datadir[@],$(datadir),g'			\
  -e 's,[@]datarootdir[@],$(datarootdir),g'		\
  -e 's,[@]localstatedir[@],$(localstatedir),g'		\
  -e 's,[@]guilemoduledir[@],$(guilemoduledir),g'	\
  -e 's,[@]guileobjectdir[@],$(guileobjectdir),g'	\
  -e 's,[@]sysconfdir[@],$(sysconfdir),g'		\
  -e 's,[@]ASD[@],$(ASD),g'				\
  -e 's,[@]LTS[@],$(LTS),g'				\
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

gaiag/%: gaiag/%.in Makefile
	$(AM_V_SED)$(do_subst) < $< > $@

BUILT_SOURCES = gaiag/config.scm

bin_SCRIPTS =					\
  bin/dzn					\
  bin/gdzn

EXTRA_DIST +=					\
 bin/dzn.in					\
 bin/gdzn.in

ALL_GO =
include gaiag/local.mk
include gash/local.mk
include gaiag/parse/local.mk
include gaiag/peg/local.mk
include gaiag/commands/local.mk
include scmcrl2/local.mk

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

check-local: check-smoke check-hello

CPUS = $(shell nproc)
check-smoke:
	./pre-inst-env test $${V:+--verbose} test/smoke

check-hello:
	./pre-inst-env test $${V:+--verbose} -j $(CPUS) test/hello

check-regression:
	./pre-inst-env test $${V:+--verbose} -j $(CPUS) test/regression

# Tests
#######

include test/gaiag/local.mk

TEST_EXTENSIONS = .scm
SCM_LOG_COMPILER = $(top_builddir)/pre-inst-env $(GUILE)
AM_SCM_LOG_FLAGS = --no-auto-compile

UNIT_TESTS =					\
  test/gaiag/lts.scm

TESTS = $(UNIT_TESTS) $(FULL_TESTS)
EXTRA_DIST += $(TESTS)

# Documentation
###############

info_TEXINFOS = doc/dezyne.texi

dezyne_TEXINFOS = doc/fdl-1.3.texi

EXTRA_DIST +=					\
  $(dezyne_TEXINFOS)

dist_man_MANS =					\
 doc/dzn.1					\
 doc/gdzn.1					\
 doc/dzn-code.1					\
 doc/dzn-hello.1				\
 doc/dzn-parse.1

doc/dzn.1: bin/dzn Makefile $(ALL_GO)
	./pre-inst-env help2man --output=$@ $<

doc/gdzn.1: bin/dzn Makefile $(ALL_GO)
	./pre-inst-env help2man --output=$@ $<

doc/dzn-code.1: bin/dzn Makefile $(ALL_GO)
	./pre-inst-env help2man --output=$@ --version-string=$(PACKAGE_VERSION) "$< code"

doc/dzn-hello.1: bin/dzn Makefile $(ALL_GO)
	./pre-inst-env help2man --output=$@ --version-string=$(PACKAGE_VERSION) "$< hello"

doc/dzn-parse.1: bin/dzn Makefile $(ALL_GO)
	./pre-inst-env help2man --output=$@ --version-string=$(PACKAGE_VERSION) "$< parse"

# Distribution
##############

# Reproducible tarball
GZIP_ENV = --no-name
am__tar = $${TAR-tar} --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner -cf - "$$tardir"

tag:
	git tag -s v$(PACKAGE_VERSION) -m "$(PACKAGE_NAME) $(PACKAGE_VERSION)."

dist-hook: gen-ChangeLog
	echo $(VERSION) > $(distdir)/.tarball-version
	git ls-tree -r --name-only HEAD > $(distdir)/.tarball-manifest

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

install-data-local:
	test -z $(DESTDIR)$(pkgdatadir) || $(MKDIR_P) $(DESTDIR)$(pkgdatadir)
	tar -cf - runtime | tar -C $(DESTDIR)$(pkgdatadir) -xf-
	tar -cf - gaiag/templates | tar -C $(DESTDIR)$(pkgdatadir) -xf-
	test -z $(DESTDIR)$(pkgdatadir) || $(MKDIR_P) $(DESTDIR)$(pkgdatadir)/test
	cd out && tar -cf - *.html | tar -C $(DESTDIR)$(pkgdatadir)/test -xf-

# Binary pack
#############

EXTRA_DIST +=					\
 bin/dzn.cmd					\
 bin/guile.cmd					\
 bin/wrapper.sh

TAR = tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner
STRIP_FILES =
dzn_linux = dzn bash-minimal coreutils guile lts m4-changeword mcrl2-minimal sed
pack:
	GUIX_PACKAGE_PATH=guix guix pack --relocatable --relocatable --symlink=/gnu/bin=bin --no-build-hook $(dzn_linux)

linux:
	rm -f $(distdir)-x86_64-linux.tar.gz
	GUIX_PACKAGE_PATH=guix guix pack --relocatable --relocatable --symlink=/gnu/bin=bin --no-build-hook $(dzn_linux)
	if test -d $(distdir); then chmod -R +w $(distdir); fi
	rm -rf $(distdir)
	mkdir $(distdir)
	tar -C $(distdir) --no-overwrite-dir -xf $$(GUIX_PACKAGE_PATH=guix guix pack --relocatable --relocatable --symlink=/gnu/bin=bin --no-build-hook $(dzn_linux))
	chmod -R +w $(distdir)
	cd $(distdir) && rm -rf $(STRIP_FILES)
	sed s,@COMMAND@,dzn, bin/wrapper.sh > $(distdir)/dzn
	chmod +x  $(distdir)/dzn
	sed s,@COMMAND@,guile, bin/wrapper.sh > $(distdir)/guile
	chmod +x  $(distdir)/guile
	cp test/all/hello/hello.dzn $(distdir)
	cp test/all/Camera/Camera.dzn $(distdir)
	$(TAR) -cf $(distdir)-x86_64-linux.tar $(distdir)
	gzip --no-name $(distdir)-x86_64-linux.tar
	rm -rf $(distdir)

dzn_mingw = dzn-mingw guile-mingw lts-mingw mcrl2-minimal-mingw
mingw:
	GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 hello
	GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 guile-mingw
#	GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 zlib-mingw
	GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 boost-mingw
	GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 mcrl2-minimal-mingw
	GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 dzn-mingw
	rm -f $(distdir)-x86_64-windows.zip
	rm -rf $(distdir)-x86_64-windows
	mkdir -p $(distdir)-x86_64-windows/lib
	cp --no-preserve=mode $$(find $$(GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 guile-json-mingw) \
              $$(guix gc -R $$(GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 $(dzn_mingw)) | grep mingw | grep -E 'dzn|guile|mcrl2') -path '*/bin/*') $(distdir)-x86_64-windows
	cp --no-preserve=mode -r $$(find $$(GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 guile-json-mingw) \
              $$(guix gc -R $$(GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 $(dzn_mingw)) | grep mingw | grep -E 'dzn|guile|mcrl2') -path '*/share') $(distdir)-x86_64-windows
	cp --no-preserve=mode -r $$(find $$(GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 guile-json-mingw) \
              $$(guix gc -R $$(GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 dzn-mingw guile-mingw) | grep mingw ) -path '*/lib/guile') $(distdir)-x86_64-windows/lib
	-cp $$(find $$(guix gc -R $$(GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 $(dzn_mingw))) -name '*.dll') $(distdir)-x86_64-windows/lib
	cp $$(find $$(guix gc -R $$(GUIX_PACKAGE_PATH=guix guix build --target=x86_64-w64-mingw32 $(dzn_mingw)) | grep -E 'dzn|guile|mcrl2') -name '*.exe') $(distdir)-x86_64-windows
#	cp --no-preserve=mode -r $$(find $$(GUIX_PACKAGE_PATH=guix guix build dzn) -path '*/dzn/info') $(distdir)-x86_64-windows/share/dzn
	cp bin/dzn $(distdir)-x86_64-windows
	cp bin/dzn.cmd $(distdir)-x86_64-windows
	cp bin/guile.cmd $(distdir)-x86_64-windows
	cp test/all/hello/hello.dzn $(distdir)
	cp test/all/Camera/Camera.dzn $(distdir)
	zip -r $(distdir)-x86_64-windows.zip $(distdir)-x86_64-windows
	rm -rf $(distdir)-x86_64-windows
