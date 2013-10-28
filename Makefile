include theos/makefiles/common.mk

TWEAK_NAME = wifieasy
wifieasy_FILES = Tweak.xm
wifieasy_FRAMEWORKS = Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
