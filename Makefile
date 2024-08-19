.DEFAULT_GOAL := all

NAME		=  s1fs2a
SUFFIX		= 
PKGCONFIG	=  pkg-config
DEBUG		?= 0
STATIC		?= 1
VERBOSE		?= 0
PROFILE		?= 0
STRIP		?= strip

# -fsigned-char required to prevent hang in LoadStageCollisions
CFLAGS		?= -fsigned-char -std=c++17
LIBS        += -lstdc++fs

# TSP Optimizations
#CFLAGS      += -mtune=cortex-a53 -mcpu=cortex-a53

# =============================================================================
# Detect default platform if not explicitly specified
# =============================================================================

ifeq ($(OS),Windows_NT)
	PLATFORM ?= Windows
else
	UNAME_S := $(shell uname -s)

	ifeq ($(UNAME_S),Linux)
		PLATFORM ?= Linux
	endif

	ifeq ($(UNAME_S),Darwin)
		PLATFORM ?= macOS
	endif

endif

ifdef EMSCRIPTEN
	PLATFORM = Emscripten
endif

PLATFORM ?= Unknown

# =============================================================================

OUTDIR = bin/$(PLATFORM)
OBJDIR = obj/$(PLATFORM)

include Makefile_cfgs/Platforms/$(PLATFORM).cfg

# =============================================================================

ifeq ($(STATIC),1)
	PKGCONFIG +=  --static
endif

ifeq ($(DEBUG),1)
	CFLAGS += -g
	STRIP = :
else
	CFLAGS += -O3
endif

ifeq ($(PROFILE),1)
	CFLAGS += -pg -g -fno-inline-functions -fno-inline-functions-called-once -fno-optimize-sibling-calls -fno-default-inline
endif

ifeq ($(VERBOSE),0)
	CC := @$(CC)
	CXX := @$(CXX)
endif

# =============================================================================

CFLAGS += `$(PKGCONFIG) --cflags sdl2 ogg vorbis theora vorbisfile theoradec`
LIBS   += `$(PKGCONFIG) --libs-only-l --libs-only-L sdl2 ogg vorbis theora vorbisfile theoradec`

#CFLAGS += -Wno-strict-aliasing -Wno-narrowing -Wno-write-strings

ifeq ($(STATIC),1)
	CFLAGS += -static
endif

INCLUDES  += \
    -I./RSDKv4/ \
    -I./RSDKv4/NativeObjects/ \
    -I./dependencies/all/asio/asio/include/ \
    -I./dependencies/all/stb-image/ \
    -I./dependencies/all/tinyxml2/ \
    -I./dependencies/all/theoraplay/

INCLUDES += $(LIBS)

# Main Sources
SOURCES = \
    RSDKv4/Animation    \
    RSDKv4/Audio        \
    RSDKv4/Collision    \
    RSDKv4/Debug        \
    RSDKv4/Drawing      \
    RSDKv4/Ini          \
    RSDKv4/Input        \
    RSDKv4/Math         \
    RSDKv4/ModAPI       \
    RSDKv4/Networking   \
    RSDKv4/Object       \
    RSDKv4/Palette      \
    RSDKv4/Reader       \
    RSDKv4/Renderer     \
    RSDKv4/RetroEngine  \
    RSDKv4/Scene        \
    RSDKv4/Scene3D      \
    RSDKv4/Script       \
    RSDKv4/Sprite       \
    RSDKv4/String       \
    RSDKv4/Text         \
    RSDKv4/Userdata     \
    RSDKv4/Video        \
    RSDKv4/main         \
    RSDKv4/NativeObjects/All                \
    dependencies/all/theoraplay/theoraplay  \
    dependencies/all/tinyxml2/tinyxml2
	
ifneq ($(FORCE_CASE_INSENSITIVE),)
	CXXFLAGS_ALL += -DFORCE_CASE_INSENSITIVE
	SOURCES += RSDKv4/fcaseopen
endif

PKGSUFFIX ?= $(SUFFIX)

BINPATH = $(OUTDIR)/$(NAME)$(SUFFIX)
PKGPATH = $(OUTDIR)/$(NAME)$(PKGSUFFIX)

OBJECTS += $(addprefix $(OBJDIR)/, $(addsuffix .o, $(SOURCES)))

$(shell mkdir -p $(OUTDIR))
$(shell mkdir -p $(OBJDIR))

$(OBJDIR)/%.o: %.c
	@mkdir -p $(@D)
	@echo -n Compiling $<...
	$(CC) -c $(CFLAGS) $(INCLUDES) $(DEFINES) $< -o $@
	@echo " Done!"

$(OBJDIR)/%.o: %.cpp
	@mkdir -p $(@D)
	@echo -n Compiling $<...
	$(CXX) -c $(CFLAGS) $(INCLUDES) $(DEFINES) $< -o $@
	@echo " Done!"

$(BINPATH): $(OBJDIR) $(OBJECTS)
	@echo -n Linking...
	$(CXX) $(CFLAGS) $(LDFLAGS) $(OBJECTS) -o $@ $(LIBS)
	@echo " Done!"
	$(STRIP) $@

ifeq ($(BINPATH),$(PKGPATH))
all: $(BINPATH)
else
all: $(PKGPATH)
endif

clean:
	rm -rf $(OBJDIR) && rm -rf $(BINPATH)