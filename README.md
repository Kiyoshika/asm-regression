# ASM Linear Regression
This is a very basic implementation of univariate OLS regression using mean squared error as the loss function and gradient descent as the optimization algorithm.

Currently the input data is loaded in the data section but in theory you can link this into a C program and call the function with custom data.

## How to Run
This is written in GAS (GNU Assembly) on Linux so it may or may not work for Windows/Macos.

I've included a makefile to assemble with `gcc` (which again, is only tested on Linux)
