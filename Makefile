game: game.o
	ld game.o -o game

game.o: game.asm
	nasm -f elf64 game.asm -o game.o

clean:
	rm -f game game.o