CC ?= cc 
PKG_CONFIG ?= pkg-config 

CFLAGS += -O2 -fPIC -std=c11 -Wall -Wextra
CFLAGS += $(shell $(PKG_CONFIG) --cflags libpipewire-0.3)

LDLIBS += $(shell $(PKG_CONFIG) --libs libpipewire-0.3)
LDLIBS += -pthread -lm

.PHONY: all clean 

all: libcapture.so

libcapture.so: capture.c
		$(CC) $(CFLAGS) -shared -o $@ $< $(LDLIBS)

clean:
		rm -f libcapture.so