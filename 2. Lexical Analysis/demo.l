%option noyywrap

%x CHAR_STATE_1
%x CHAR_STATE_2
%x CHAR_STATE_3
%x CHAR_STATE_ERROR
%x STR_STATE_1
%x STR_STATE_2
%x STR_STATE_ERROR

%{
 #include <iostream>
 #include <cstdlib>
 #include <string>
 using namespace std;

 string textChar;
 string textStr;
%}

digit [0-9]

%%
"if" {cout << "IF keyword found\n";}
"else" {cout << "ELSE keyword found\n";}
"for" {cout << "FOR keyword found\n";}
"while" {cout << "WHILE keyword found\n";}
"do" {cout << "DO keyword found\n";}
"break" {cout << "BREAK keyword found\n";}
"int" {cout << "INT keyword found\n";}
"float" {cout << "FLOAT keyword found\n";}
"double" {cout << "DOUBLE keyword found\n";}
"void" {cout << "VOID keyword found\n";}
"return" {cout << "RETURN keyword found\n";}
"switch" {cout << "SWITCH keyword found\n";}
"case" {cout << "CASE keyword found\n";}
"default" {cout << "DEFAULT keyword found\n";}
"continue" {cout << "CONTINUE keyword found\n";}
[+-]?{digit}+ {cout << "CONST_INT found " << yytext << endl;}
[+-]?[0-9]*[.][0-9]+([E][-]?[0-9]+)?|[+-]?[0-9]+[E][-]?[0-9]+ {cout << "CONST_FLOAT found " << yytext << endl;}
[+-]?[0-9]*[.][0-9]+([E][-]?[0-9]*)?[.]. {cout << "Error matching float: multiple decimal points";}
' {BEGIN CHAR_STATE_1;}
<CHAR_STATE_1>[^\\.] {textChar = yytext; BEGIN CHAR_STATE_2;}
<CHAR_STATE_1>[\\] {BEGIN CHAR_STATE_3;}
<CHAR_STATE_2>[^\'.] {BEGIN CHAR_STATE_ERROR;}
<CHAR_STATE_2>' {cout << "CONST_CHAR found " << (textChar==" "? "' '":textChar) << endl; textChar=""; BEGIN INITIAL;}
<CHAR_STATE_3>[t|n|a|b|f|v|r|\\|\'|0] {textChar = yytext; textChar = "\\"+textChar; BEGIN CHAR_STATE_2;}
<CHAR_STATE_ERROR>' {cout << "Error matching char: multiple characters\n"; textChar=""; BEGIN INITIAL;}
<CHAR_STATE_ERROR>[^\'.] {}
[_A-Za-z][A-Za-z0-9_]* {cout << "Identifier found "<< yytext << "\n";}
"+"|"-" {cout << "ADDOP found\n";}
"/"|"*"/"%" {cout << "MULOP found\n";}
"=" {cout << "ASSIGNOP found\n";}
"&&"|"||" {cout << "LOGICOP found\n";}
"(" {cout << "LPAREN found\n";}
")" {cout << "RPAREN found\n";}
"!" {cout << "NOT found\n";}
"++"|"--" {cout << "INCOP found\n";}
"<"|"<="|">"|">="|"=="|"!=" {cout << "RELOP found\n";}
"[" {cout << "LTHIRD found\n";}
"]" {cout << "RTHIRD found\n";}
"," {cout << "COMMA found\n";}
";" {cout << "SEMICOLON found\n";}
"{" {cout << "LCURL found\n";}
"}" {cout << "RCURL found\n";}
["] {textStr = ""; BEGIN STR_STATE_1;}
<STR_STATE_1>[^"\n\\] {textStr += yytext;}
<STR_STATE_1>[\\] {BEGIN STR_STATE_2;}
<STR_STATE_2>[t|a|b|f|v|r|\\|\'|0] {textChar = yytext; textStr += "\\"+textChar; textChar=""; BEGIN STR_STATE_1;}
<STR_STATE_2>[^"\n\\] {textStr += yytext; BEGIN STR_STATE_1;}
<STR_STATE_2>[\n] {textStr += "\\n"; BEGIN STR_STATE_1;}
<STR_STATE_1>["] {cout << "STRING found " << textStr << endl; textStr=""; BEGIN INITIAL;}
<STR_STATE_1><<EOF>> {cout << "Error: Unfinished string\n"; BEGIN INITIAL;}
<STR_STATE_1>[\n] {BEGIN STR_STATE_ERROR;}
<STR_STATE_ERROR>["] {cout << "Invalid string format\n"; BEGIN INITIAL;}
<STR_STATE_ERROR>[^".|\n] {}
<STR_STATE_ERROR><<EOF>> {cout << "Invalid string format\n"; BEGIN INITIAL;}
[ ] {}
%%

int main(int argc, char* argv[], char* envp[]){
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
