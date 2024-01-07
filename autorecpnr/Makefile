THEOS_DEVICE_IP = 192.168.0.181
TARGET := iphone:clang:12.4

include $(THEOS)/makefiles/common.mk

TOOL_NAME = AutoReceivePNR

AutoReceivePNR_FILES = main.m
AutoReceivePNR_CFLAGS = -fobjc-arc
AutoReceivePNR_CODESIGN_FLAGS = -Sentitlements.plist
AutoReceivePNR_INSTALL_PATH = /usr/local/bin
AutoReceivePNR_FRAMEWORKS = UIKit Foundation
AutoReceivePNR_LIBRARIES = mryipc

include $(THEOS_MAKE_PATH)/tool.mk
