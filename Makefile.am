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
 guix/gnu/packages/dzn.scm

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

BUILT_SOURCES =

bin_SCRIPTS =					\
  bin/dzn

EXTRA_DIST +=					\
 bin/dzn.in

ALL_GO =
include gaiag/local.mk
include gash/local.mk
include gaiag/parse/local.mk
include gaiag/peg/local.mk
include gaiag/commands/local.mk
include runtime/local.mk
include scmcrl2/local.mk
include gaiag/templates/local.mk

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
include test/bin/local.mk
include test/gaiag/local.mk
include test/lib/local.mk

TEST_EXTENSIONS = .scm
LOG_COMPILER = $(top_builddir)/pre-inst-env run
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

MAKEINFO_HTML_OPTIONS =									\
 --css-ref=https://www.gnu.org/software/gnulib/manual.css				\
 -c EXTRA_HEAD='<meta name="viewport" content="width=device-width, initial-scale=1" />'

# Ask for warnings about cross-referenced manuals that are not listed in
# htmlxref.cnf.
EXTRA_DIST += .texinfo/htmlxref.cnf
AM_MAKEINFOHTMLFLAGS = --set-customization-variable CHECK_HTMLXREF=true

doc/html/index.html: ${srcdest}doc/dezyne.texi doc/version.texi $(WEB_IMAGES)
	mkdir -p $(@D)/html_node
	$(MAKEINFO) --html $(MAKEINFO_HTML_OPTIONS) -o $(@D)/html_node -I ${srcdest}doc -I doc $<
	$(MAKEINFO) --no-split --html $(MAKEINFO_HTML_OPTIONS) -o $(@D)/dezyne.html -I ${srcdest}doc -I doc $<

SITE = /srv/dezyne
publish: html pdf
	rsync -P -v . $(SITE)/
	rsync -P -v . $(SITE)/manual/
	rsync -P -rvz --delete doc/html/ $(SITE)/manual/
	rsync -P -rvz --delete doc/images $(SITE)/manual/
	rsync -P -rvz --delete doc/images $(SITE)/manual/html_node/
	rsync -P -rvz doc/dezyne.pdf $(SITE)/manual/

LOCAL_SITE = $(HOME)/src/web/dezyne.org/site/dezyne
publish-local: html pdf
	rsync -P -v . $(LOCAL_SITE)/
	rsync -P -v . $(LOCAL_SITE)/manual/
	rsync -P -rvz --delete doc/html/ $(LOCAL_SITE)/manual/
	rsync -P -rvz --delete doc/images $(LOCAL_SITE)/manual/
	rsync -P -rvz --delete doc/images $(LOCAL_SITE)/manual/html_node/
	rsync -P -rvz  doc/dezyne.pdf $(LOCAL_SITE)/manual/

# Distribution
##############

# Release process
#  0. Prepare for release
#     - fix all tests, or add failing tests to XFAIL_TESTS
#     - doc: Release update (NEWS, etc.)
#     - git clean -fdx
#     - ./autogen.sh; ./configure; make
#  1. make tag PACKAGE_VERSION=X.Y
#  2. make sign-dist
#  3. make release
#  4. test guix package build, binary packs (see HACKING)
#     GUIX_PACKAGE_PATH=guix build dzn
#     make linux
#     make mingw
#  5. Send mail to
#     guile-devel@gnu.org
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

# FIXME: this will only work after we switch to source tarball
# distribution and url-feth
release: update-hash
	git commit -m 'guix: Update hash.'				\
		-m '* guix/gnu/packages/dzn.scm (dzn): Update hash.'	\
		guix/gnu/packages/dzn.scm

if have_guix
update-hash: $(DIST_ARCHIVES)
	$(GUIX) download file://$(PWD)/$<
	sed -i \
		-e 's,base32 #!dzn!# "[^"]*"),base32 #!dzn!# "$(shell $(GUIX) hash $<)"),' \
		-e 's,version #!dzn!# "[^"]*"),version #!dzn!# "$(PACKAGE_VERSION)"),' \
	guix/gnu/packages/dzn.scm
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

install-data-local:
	test -z $(DESTDIR)$(pkgdatadir) || $(MKDIR_P) $(DESTDIR)$(pkgdatadir)
if have_cxx11
	tar -cf - runtime/c++ | tar -C $(DESTDIR)$(pkgdatadir) -xf-
endif
if have_javascript
	tar -cf - runtime/javascript | tar -C $(DESTDIR)$(pkgdatadir) -xf-
endif
if have_scheme
	tar -cf - runtime/scheme | tar -C $(DESTDIR)$(pkgdatadir) -xf-
endif

# Binary pack
#############

EXTRA_DIST +=					\
 bin/dzn.cmd					\
 bin/guile.cmd					\
 bin/wrapper.sh

PACK_TAR = tar --sort=name --mtime=@1 --owner=0 --group=0 --numeric-owner

dzn_linux =					\
 bash-minimal					\
 coreutils					\
 dzn						\
 guile-piped-process				\
 m4-changeword					\
 mcrl2-minimal-patched				\
 sed

STRIP_FILES =					\
 gnu/store/*-boost*				\
 gnu/store/*/include

TAR = tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner

dzn_linux = dzn bash-minimal coreutils guile-piped-process m4-changeword mcrl2-minimal-patched sed
pack:
	GUIX_PACKAGE_PATH=guix guix pack --relocatable --relocatable --symlink=/gnu/bin=bin --no-offload $(dzn_linux)

linux:
	GUIX_PACKAGE_PATH=guix guix build dzn
	rm -f $(distdir)-x86_64-linux.tar.gz
	GUIX_PACKAGE_PATH=guix guix pack --relocatable --relocatable --symlink=/gnu/bin=bin --symlink=/gnu/lib=lib --symlink=/gnu/share=share --no-offload $(dzn_linux)
	if test -d $(distdir); then chmod -R +w $(distdir); fi
	rm -rf $(distdir)
	mkdir $(distdir)
	tar -C $(distdir) --no-overwrite-dir -xf $$(GUIX_PACKAGE_PATH=guix guix pack --relocatable --relocatable --symlink=/gnu/bin=bin --symlink=/gnu/lib=lib --symlink=/gnu/share=share --no-offload $(dzn_linux))
	chmod -R +w $(distdir)
	cd $(distdir) && rm -rf $(STRIP_FILES)
	sed s,@COMMAND@,dzn, bin/wrapper.sh > $(distdir)/dzn
	chmod +x  $(distdir)/dzn
	sed s,@COMMAND@,guile, bin/wrapper.sh > $(distdir)/guile
	chmod +x  $(distdir)/guile
	sed s,@COMMAND@,dzn-env, bin/dzn-env.sh > $(distdir)/dzn-env
	chmod +x  $(distdir)/dzn-env
	cp test/all/hello/hello.dzn $(distdir)
	cp test/all/compliance_provides_bool/compliance_provides_bool.dzn $(distdir)
	cp test/all/Camera/Camera.dzn $(distdir)
	$(PACK_TAR) -cf $(distdir)-x86_64-linux.tar $(distdir)
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
