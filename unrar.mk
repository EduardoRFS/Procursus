ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += unrar
DOWNLOAD      += https://www.rarlab.com/rar/unrarsrc-$(UNRAR_VERSION).tar.gz
UNRAR_VERSION := 5.9.2
DEB_UNRAR_V   ?= $(UNRAR_VERSION)

unrar-setup: setup
	$(call EXTRACT_TAR,unrarsrc-$(UNRAR_VERSION).tar.gz,n/a,unrar)

ifneq ($(wildcard $(BUILD_WORK)/unrar/.build_complete),)
unrar:
	@echo "Using previously built unrar."
else
unrar: unrar-setup
	$(SED) -i 's/libunrar.so/libunrar.dylib/g' $(BUILD_WORK)/unrar/makefile
	+$(MAKE) -C $(BUILD_WORK)/unrar \
		CXX="$(CXX) $(CFLAGS)" \
		STRIP=$(STRIP)
	+$(MAKE) -C $(BUILD_WORK)/unrar clean
	+$(MAKE) -C $(BUILD_WORK)/unrar lib \
		CXX="$(CXX) $(CFLAGS)" \
		AR="$(AR)" \
		STRIP=$(STRIP)
	mkdir -p $(BUILD_STAGE)/unrar/usr/{bin,lib}
	cd $(BUILD_WORK)/unrar; \
		cp -af unrar $(BUILD_STAGE)/unrar/usr/bin; \
		cp -af libunrar.dylib $(BUILD_STAGE)/unrar/usr/lib
	touch $(BUILD_WORK)/unrar/.build_complete
endif

unrar-package: unrar-stage
	# unrar.mk Package Structure
	rm -rf $(BUILD_DIST)/unrar
	mkdir -p $(BUILD_DIST)/unrar/bin
	
	# unrar.mk Prep unrar
	cp -a $(BUILD_STAGE)/unrar/usr $(BUILD_DIST)/unrar
	
	# unrar.mk Sign
	$(call SIGN,unrar,general.xml)
	
	# unrar.mk Make .debs
	$(call PACK,unrar,DEB_UNRAR_V)
	
	# unrar.mk Build cleanup
	rm -rf $(BUILD_DIST)/unrar

.PHONY: unrar unrar-package
