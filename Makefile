.PHONY: run clean


game: game.o
	gcc -no-pie game.o -o game $(shell sdl2-config --libs)

game.o: game.asm
	nasm -f elf64 game.asm -o game.o

run: game
	./game

clean:
	rm -f game game.o