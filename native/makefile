CC ?= cc 
CFLAGS := -02 -fPIC -std=c11 -Wall -Wextra $(shell pkg-config --cflags
libpipewire-0.3)
LIBS := $(shell pkg-config --libs libpipewire-0.3) -pthread -lm

all: libcapture.so

libcapture.so: capture.c 
	$(CC) $(CFLAGS) -shared -o $@ $< $(LIBS)

clean:
	rm -f libcapture.so