all: server

server: server.cpp makefile
	g++ server.cpp -lpthread ../libMPU6050.so -I ../ -o server

run: server
	./server
