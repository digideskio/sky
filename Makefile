################################################################################
# Variables
################################################################################

CFLAGS=-g -Wall -Wextra -Wno-self-assign -Wno-error=unknown-warning -std=c99 -D_FILE_OFFSET_BITS=64

SOURCES=$(wildcard src/**/*.c src/**/**/*.c src/*.c)
OBJECTS=$(patsubst %.c,%.o,${SOURCES}) $(patsubst %.l,%.o,${LEX_SOURCES}) $(patsubst %.y,%.o,${YACC_SOURCES})
BIN_SOURCES=src/skyd.c,src/sky_bench.c,src/sky_gen.c
BIN_OBJECTS=$(patsubst %.c,%.o,${BIN_SOURCES})
LIB_SOURCES=$(filter-out ${BIN_SOURCES},${SOURCES})
LIB_OBJECTS=$(filter-out ${BIN_OBJECTS},${OBJECTS})
TEST_SOURCES=$(wildcard tests/*_tests.c tests/**/*_tests.c)
TEST_OBJECTS=$(patsubst %.c,%,${TEST_SOURCES})

PREFIX?=/usr/local

################################################################################
# Main Targets
################################################################################

compile: bin/libsky.a bin/skyd bin/sky-gen bin/sky-bench
all: compile test


################################################################################
# Installation
################################################################################

install: all
	install -d $(DESTDIR)/$(PREFIX)/sky/
	install -d $(DESTDIR)/$(PREFIX)/sky/bin/
	install -d $(DESTDIR)/$(PREFIX)/sky/data/
	install bin/skyd $(DESTDIR)/$(PREFIX)/sky/bin/
	rm $(DESTDIR)/$(PREFIX)/bin/skyd
	ln -s $(DESTDIR)/$(PREFIX)/sky/bin/skyd $(DESTDIR)/$(PREFIX)/bin/skyd

################################################################################
# Binaries
################################################################################

bin/libsky.a: bin ${LIB_OBJECTS}
	rm -f bin/libsky.a
	ar rcs $@ ${LIB_OBJECTS}
	ranlib $@

bin/skyd: bin ${OBJECTS} bin/libsky.a
	$(CC) $(CFLAGS) -Isrc -o $@ src/skyd.c bin/libsky.a
	chmod 700 $@

bin/sky-gen: bin ${OBJECTS} bin/libsky.a
	$(CC) $(CFLAGS) src/sky_gen.o -o $@ bin/libsky.a
	chmod 700 $@

bin/sky-bench: bin ${OBJECTS} bin/libsky.a
	$(CC) $(CFLAGS) -Isrc -o $@ src/sky_bench.c bin/libsky.a
	chmod 700 $@

bin:
	mkdir -p bin


################################################################################
# jsmn
################################################################################

src/jsmn/jsmn.o: src/jsmn/jsmn.c
	$(CC) $(CFLAGS) -Wno-sign-compare -Isrc -c -o $@ $<


################################################################################
# Tests
################################################################################

.PHONY: test
test: $(TEST_OBJECTS) tmp
	@sh ./tests/runtests.sh

$(TEST_OBJECTS): %: %.c bin/libsky.a
	$(CC) $(CFLAGS) -Isrc -o $@ $< bin/libsky.a


################################################################################
# Misc
################################################################################

tmp:
	mkdir -p tmp

clean: 
	rm -rf bin ${OBJECTS} ${TEST_OBJECTS} ${LEX_OBJECTS} ${YACC_OBJECTS}
	rm -rf tests/*.dSYM tests/*.o
	rm -rf tmp/*
