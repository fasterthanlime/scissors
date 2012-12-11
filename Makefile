ROCK_DIST?=../rock/

MYOS := $(shell uname -s)
ifeq ($(MYOS), CYGWIN_NT-5.1)
  ARCH=win
else ifeq ($(MYOS), CYGWIN_NT-5.1)
  ARCH=win
else ifeq ($(MYOS), MINGW32_NT-6.1)
  ARCH=win
else
  ARCH=unix
endif

ifeq ($(ARCH), win)
  OOCFLAGS:='-DROCK_BUILD_DATE=\"lib\"' '-DROCK_BUILD_TIME=\"lib\"'
else
  OOCFLAGS:='-DROCK_BUILD_DATE="lib"' '-DROCK_BUILD_TIME="lib"'
endif

all:
	rock -v source/scissors $(OOCFLAGS) -o=bin/scissors

nagaqueen:
	gcc $(ROCK_DIST)/source/rock/frontend/NagaQueen.c -std=c99 -O3 -fomit-frame-pointer -D__OOC_USE_GC__ -w -c -o third-party/nagaqueen.o
	ar cr third-party/libnagaqueen.a third-party/nagaqueen.o

random:
	rock -g -v --nolines --sourcepath=samples random $(OOCFLAGS)

clean:
	rock -x

.PHONY: all clean random
