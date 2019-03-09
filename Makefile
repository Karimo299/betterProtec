include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BetterProtec
BetterProtec_FILES = Tweak.xm
BetterProtec_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += betterprotec
include $(THEOS_MAKE_PATH)/aggregate.mk
