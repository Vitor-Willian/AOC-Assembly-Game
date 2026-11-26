.PHONY: run clean


game: game.o
	gcc -no-pie game.o -o game $(shell sdl2-config --libs) -lSDL2_mixer

game.o: game.asm pause_menu.inc
	nasm -f elf64 game.asm -o game.o

run: game
	./game

clean:
	rm -f game game.o