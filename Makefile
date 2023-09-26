.PHONY: run

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

run:
	$(LOVE) .