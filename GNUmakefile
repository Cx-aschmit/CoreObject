PACKAGE_NAME = CoreObject

include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = CoreObject
VERSION = 0.5

LIBRARIES_DEPEND_UPON = -lEtoileFoundation $(GUI_LIBS) $(FND_LIBS) $(OBJC_LIBS) $(SYSTEM_LIBS)

CC = clang
CXX = clang
LD = $(CXX)

CoreObject_INCLUDE_DIRS = -Ifmdb/src 
CoreObject_CPPFLAGS = -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS
CoreObject_LDFLAGS += -lstdc++ -lobjcxx

ifeq ($(test), yes)
  BUNDLE_NAME = $(FRAMEWORK_NAME)
  CoreObject_LDFLAGS += -lEtoileFoundation $(GUI_LIBS) $(FND_LIBS) $(OBJC_LIBS) $(SYSTEM_LIBS)
  CoreObject_PRINCIPAL_CLASS = TestCommon
endif

OTHER_HEADER_DIRS = Core Diff Model Store Tracks Utilities

CoreObject_HEADER_FILES_DIR = Headers
CoreObject_HEADER_FILES = $(notdir $(wildcard Headers/*.h))

CoreObject_OBJC_FILES += $(wildcard Core/*.m)
CoreObject_OBJC_FILES += $(wildcard Diff/*.m)
CoreObject_OBJCC_FILES = $(wildcard Diff/*.mm)
CoreObject_OBJC_FILES += $(wildcard Model/*.m)
CoreObject_OBJC_FILES += $(wildcard Store/*.m)
CoreObject_C_FILES = $(wildcard Store/*.c)
CoreObject_OBJC_FILES += $(wildcard Tracks/*.m)
CoreObject_OBJC_FILES += $(wildcard Utilities/*.m)

CoreObject_OBJC_FILES += $(wildcard fmdb/src/*.m)

ifeq ($(test), yes)
CoreObject_OBJC_FILES += \
	TestArrayDiff.m \
	TestCollection.m \
	TestCommon.m \
	TestCopy.m \
	TestCommitTrack.m \
	TestCustomTrack.m \
	TestEditingContext.m \
	TestHistoryTrack.m \
	TestObjectGraphDiff.m \
	TestPerformance.m \
	TestRelationshipIntegrity.m \
	TestRevisionNumber.m \
	TestSynchronization.m \
	TestStore.m \
	TestUtilities.m
endif

clean : test=yes

include $(GNUSTEP_MAKEFILES)/aggregate.make
ifeq ($(test), yes)
  include $(GNUSTEP_MAKEFILES)/bundle.make
else	
  include $(GNUSTEP_MAKEFILES)/framework.make
endif
-include ../../etoile.make
-include etoile.make
