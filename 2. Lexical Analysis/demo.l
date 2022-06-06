%option noyywrap

%{
 #include <stdio.h>
 #include <stdlib.h>
%}

digit [0-9]

%%
[_A-Za-z][A-Za-z0-9_]* {printf("identifier found\n");}
"+"|"-" {printf("ADDOP found\n");}
"/"|"*"/"%" {printf("MULOP found\n");}
"=" {printf("ASSIGNOP found\n");}
"&&"|"||" {printf("LOGICOP found\n");}
"(" {printf("LPAREN found\n");}
")" {printf("RPAREN found\n");}
"!" {printf("NOT found\n");}
"++"|"--" {printf("INCOP found\n");}
"<"|"<="|">"|">="|"=="|"!=" {printf("RELOP found\n");}
"[" {printf("LTHIRD found\n");}
"]" {printf("RTHIRD found\n");}
"," {printf("COMMA found\n");}
";" {printf("SEMICOLON found\n");}
%%

int main(int argc, char* argv[]){
 if(argc != 2){
  printf("Please provide input file name!");
  return 0;
 }

 FILE* fin = fopen(argv[1], "r");
 if(fin == NULL){
  printf("Cannot open specified file\n");
  return 0;
 }

 yyin = fin;
 yylex();
 fclose(yyin);
 return 0;
}
