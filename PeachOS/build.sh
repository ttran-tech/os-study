#/bin/bash
# This script sets up the PATH to the cross compiler. 
# Allows the Makefile to locate and execute GCC Cross Compiler instead of the system compiler.

export PREFIX="$HOME/opt/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"

make all