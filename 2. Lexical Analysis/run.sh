flex -o $1.cpp $1.l
g++ $1.cpp -lfl -o $1.out
./$1.out $1.txt
