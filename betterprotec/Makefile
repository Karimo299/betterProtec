include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = BetterProtec
BetterProtec_FILES = BPCRootListController.m
BetterProtec_INSTALL_PATH = /Library/PreferenceBundles
BetterProtec_FRAMEWORKS = UIKit
BetterProtec_PRIVATE_FRAMEWORKS = Preferences
BetterProtec_LIBRARIES = applist
# BetterProtec_EXTRA_FRAMEWORKS = Cephei CepheiPrefs

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/BetterProtec.plist$(ECHO_END)
