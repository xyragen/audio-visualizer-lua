CC ?= cc 
PKG_CONFIG ?= pkg-config 

CFLAGS += -02 -fPIC -std=c11 -Wall -Wextra
CFLAGS += $(shell $ (PKG_CONFIG) --cflags libpipewire-0.3)

LIBS := $(shell $(PKG_CONFIG) --libs libpipewire-0.3) -pthreads -lm
.PHONY: all clean

all: libcapture.so

libcapture.so: capture.c 
		$(CC) $(CFLAGS) -shared -o $@ $< $(LIBS)

clean:
		rm -f libcapture.so