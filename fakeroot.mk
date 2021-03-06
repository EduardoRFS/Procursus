ifneq ($(PROCURSUS),1)
$(error Use the main Makefakeroot)
endif

SUBPROJECTS        += fakeroot
DOWNLOAD           += https://deb.debian.org/debian/pool/main/f/fakeroot/fakeroot_$(FAKEROOT_VERSION).orig.tar.gz
FAKEROOT_VERSION   := 1.24
DEB_FAKEROOT_V     ?= $(FAKEROOT_VERSION)

fakeroot-setup: setup
	$(call EXTRACT_TAR,fakeroot_$(FAKEROOT_VERSION).orig.tar.gz,fakeroot-$(FAKEROOT_VERSION),fakeroot)
	for file in $(BUILD_WORK)/fakeroot/{communicate.{c,h},faked.c,libfakeroot{,_unix2003}.c,wrapfunc.inp}; do \
		$(SED) -i 's/struct stat64/struct stat/g' $$file; \
		$(SED) -i '/_DARWIN_NO_64_BIT_INODE/d' $$file; \
		$(SED) -i 's/int who/id_t who/g' $$file; \
	done
	$(SED) -i '/INT_STRUCT_STAT struct stat/d' $(BUILD_WORK)/fakeroot/libfakeroot_unix2003.c
	$(SED) -i '/$$INODE64/d' $(BUILD_WORK)/fakeroot/wrapfunc.inp
	$(SED) -i 's/libmacosx.la $$(LTLIBOBJS)/$$(LTLIBOBJS)/g' $(BUILD_WORK)/fakeroot/Makefile.in

ifneq ($(wildcard $(BUILD_WORK)/fakeroot/.build_complete),)
fakeroot:
	@echo "Using previously built fakeroot."
else
fakeroot: fakeroot-setup
	cd $(BUILD_WORK)/fakeroot && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-ipc=tcp \
		ac_cv_func_openat=no
	$(SED) -i 's/SETGROUPS_SIZE_TYPE unknown/SETGROUPS_SIZE_TYPE int/g' $(BUILD_WORK)/fakeroot/config.h
	+$(MAKE) -C $(BUILD_WORK)/fakeroot \
		CFLAGS='$(CFLAGS) -D__DARWIN_UNIX03 -DMAC_OS_X_VERSION_MIN_REQUIRED=1000'
	+$(MAKE) -C $(BUILD_WORK)/fakeroot install \
		DESTDIR=$(BUILD_STAGE)/fakeroot
	touch $(BUILD_WORK)/fakeroot/.build_complete
endif

fakeroot-package: fakeroot-stage
	# fakeroot.mk Package Structure
	rm -rf $(BUILD_DIST)/fakeroot
	mkdir -p $(BUILD_DIST)/fakeroot
	
	# fakeroot.mk Prep fakeroot
	cp -a $(BUILD_STAGE)/fakeroot/usr $(BUILD_DIST)/fakeroot
	
	# fakeroot.mk Sign
	$(call SIGN,fakeroot,general.xml)
	
	# fakeroot.mk Make .debs
	$(call PACK,fakeroot,DEB_FAKEROOT_V)
	
	# fakeroot.mk Build cleanup
	rm -rf $(BUILD_DIST)/fakeroot

.PHONY: fakeroot fakeroot-package
