.PHONY: run clean build love windows

ifeq ($(OS),Windows_NT)
# Windows
LOVE:=lovec
else
ifneq ($(shell stat /proc/sys/fs/binfmt_misc/WSLInterop 2>/dev/null),)
# WSL
LOVE:=lovec.exe
else
# Posix
LOVE:=love
endif
endif

LUA_SOURCE:=$(wildcard *.lua) lithium/init.lua lithium/common.lua lithium/table.lua lithium/io.lua lithium/string.lua lithium/math.lua lithium/color.lua lithium/vec2.lua 
MOONSCRIPT_SOURCE:=$(wildcard *.moon) $(wildcard module/*.moon) $(wildcard widget/*.moon)
LUA_COMPILED:=$(patsubst %.moon,%.lua,$(MOONSCRIPT_SOURCE))

WANTED_LUA:=$(LUA_COMPILED) $(LUA_SOURCE)
BUILT_FILES:=$(patsubst %.lua,build/raw/%.lua,$(WANTED_LUA)) $(patsubst %,build/raw/%,$(wildcard font/**))

BUILT_LOVE:=build/sound_maker.love
BUILT_WINDOWS:=build/sound_maker_windows.zip

build/raw/%.lua: %.moon
	@busybox mkdir -p $(shell busybox dirname $@)
	@moonc -o $@ $<

build/raw/%.lua: %.lua
	@busybox mkdir -p $(shell busybox dirname $@)
	busybox cp $< $@

build/raw/%.txt: %.txt
	@busybox mkdir -p $(shell busybox dirname $@)
	busybox cp $< $@

build/raw/%.ttf: %.ttf
	@busybox mkdir -p $(shell busybox dirname $@)
	busybox cp $< $@

run:
	$(LOVE) . --moonscript --display 2 --no-vsync --no-hint-overlay

build: $(BUILT_LOVE) $(BUILT_WINDOWS)

$(BUILT_LOVE): $(BUILT_FILES)
	busybox rm -f $(BUILT_LOVE)
	7z a -bd -tzip -mx0 -r $@ ./build/raw/*

$(BUILT_WINDOWS): $(BUILT_LOVE)
	busybox rm -f $(BUILT_WINDOWS)
	7z a -bd $(BUILT_WINDOWS) $(wildcard ./love/*.dll)
	busybox cat love/love.exe $(BUILT_LOVE) > build/sound_maker.exe
	7z a -bd $(BUILT_WINDOWS) ./build/sound_maker.exe
	rm -f build/sound_maker.exe

love: $(BUILT_LOVE)
windows: $(BUILT_WINDOWS)

clean:
	busybox rm -rf build