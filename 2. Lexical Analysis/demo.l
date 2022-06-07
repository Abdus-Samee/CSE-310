%option noyywrap

%{
 #include <stdio.h>
 #include <stdlib.h>
%}

digit [0-9]

%%
"if" {printf("IF keyword found\n");}
"else" {printf("ELSE keyword found\n");}
"for" {printf("FOR keyword found\n");}
"while" {printf("WHILE keyword found\n");}
"do" {printf("DO keyword found\n");}
"break" {printf("BREAK keyword found\n");}
"int" {printf("INT keyword found\n");}
"float" {printf("FLOAT keyword found\n");}
"double" {printf("DOUBLE keyword found\n");}
"void" {printf("VOID keyword found\n");}
"return" {printf("RETURN keyword found\n");}
"switch" {printf("SWITCH keyword found\n");}
"case" {printf("CASE keyword found\n");}
"default" {printf("DEFAULT keyword found\n");}
"continue" {printf("CONTINUE keyword found\n");}
[+-]?{digit}+ {printf("CONST_INT found %s\n", yytext);}
[+-]?[0-9]*[.][0-9]+([E][-]?[0-9]+)?|[+-]?[0-9]+[E][-]?[0-9]+ {printf("CONST_FLOAT found %s \n", yytext);}
[+-]?[0-9]*[.][0-9]+([E][-]?[0-9]*)?[.]. {printf("Error matching float: multiple decimal points");}
'[A-Za-z0-9]' {printf("CONST_CHAR found %d\n", yytext[1]);}
'[A-Za-z0-9][A-Za-z0-9]+' {printf("Error matching char: multiple characters");}
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
"{" {printf("LCURL found\n");}
"}" {printf("RCURL found\n");}
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
