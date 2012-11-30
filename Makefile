
OOCFLAGS:='-DROCK_BUILD_DATE="lib"' '-DROCK_BUILD_TIME="lib"' ~/Dev/rock/.libs/NagaQueen.o

all:
	rock -v source/scissors $(OOCFLAGS) -o=bin/scissors

clean:
	rock -x

.PHONY: all clean
