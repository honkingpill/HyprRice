CC = gcc
CFLAGS = -O2 -Wall
TARGET = hyprlock-music-plugin

all: $(TARGET)

$(TARGET): music-plugin.c
	$(CC) $(CFLAGS) -o $(TARGET) music-plugin.c

clean:
	rm -f $(TARGET)

install: $(TARGET)
	cp $(TARGET) /usr/local/bin/

uninstall:
	rm -f /usr/local/bin/$(TARGET)

.PHONY: all clean install uninstall
