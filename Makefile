ROCK_DIST?=../rock/

OOCFLAGS:='-DROCK_BUILD_DATE=\"lib\"' '-DROCK_BUILD_TIME=\"lib\"'

all:
	rock -v source/scissors $(OOCFLAGS) -o=bin/scissors

nagaqueen:
	gcc $(ROCK_DIST)/source/rock/frontend/NagaQueen.c -std=c99 -O3 -fomit-frame-pointer -D__OOC_USE_GC__ -w -c -o third-party/nagaqueen.o
	ar cr third-party/libnagaqueen.a third-party/nagaqueen.o

random:
	rock -g -v --sourcepath=samples random $(OOCFLAGS)

clean:
	rock -x

.PHONY: all clean random
