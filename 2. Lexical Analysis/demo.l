%option noyywrap

%x CHAR_STATE_1
%x CHAR_STATE_2
%x CHAR_STATE_3
%x CHAR_STATE_ERROR
%x STR_STATE_1
%x STR_STATE_2
%x STR_NULL_STATE
%x STR_STATE_ERROR

%{
 #include <iostream>
 #include <cstdlib>
 #include <string>
 #include <cstring>
 #include <cctype>
 #include <fstream>
 #include "1805021_SymbolTable.h"

 #define BUCKETS 7

 using namespace std;

 string textChar;
 string textStr;
 fstream tokenFile;
 SymbolTable symbolTable(BUCKETS);

 string toUpperCase(char* s){
    string res = s;
    for(int i = 0; i < res.length(); i++){
        res[i] = toupper(res[i]);
    }
    return res;
 }

 string getSpecial(char* c){
    string s = c;
    if(s == "n") return "\n";
    else if(s == "t") return "\t";
    else if(s == "r") return "\r";
    else if(s == "a") return "\a";
    else if(s == "b") return "\b";
    else if(s == "f") return "\f";
    else if(s == "v") return "\v";
    else if(s == "\\") return "\\";
    else if(s == "\'") return "\'";
    else if(s == "0") return "\0";

    return "";
 }
%}

digit [0-9]
keyword "if"|"else"|"for"|"while"|"do"|"break"|"int"|"float"|"double"|"void"|"return"|"switch"|"case"|"default"|"continue"
special [t|n|a|b|f|v|r|\|'|0]

%%
{keyword} {tokenFile<<"<"<<toUpperCase(yytext)<<"> ";}
[+-]?{digit}+ {tokenFile<<"<CONST_INT, "<<yytext<<"> ";}
[+-]?[0-9]*[.][0-9]+([E][-]?[0-9]+)?|[+-]?[0-9]+[E][-]?[0-9]+ {tokenFile<<"<CONST_FLOAT, "<<yytext<<"> ";}
[+-]?[0-9]*[.][0-9]+([E][-]?[0-9]*)?[.]. {cout << "Error matching float: multiple decimal points";}
' {BEGIN CHAR_STATE_1;}
<CHAR_STATE_1>[^\\.] {textChar = yytext; BEGIN CHAR_STATE_2;}
<CHAR_STATE_1>[\\] {BEGIN CHAR_STATE_3;}
<CHAR_STATE_2>[^\'.] {BEGIN CHAR_STATE_ERROR;}
<CHAR_STATE_2>' {textChar=(textChar==" "? "''":textChar);tokenFile<<"<CONST_CHAR, "<<textChar<<"> ";textChar=""; BEGIN INITIAL;}
<CHAR_STATE_3>{special} {textChar = getSpecial(yytext); BEGIN CHAR_STATE_2;}
<CHAR_STATE_ERROR>' {cout << "Error matching char: multiple characters\n"; textChar=""; BEGIN INITIAL;}
<CHAR_STATE_ERROR>[^\'.] {}
[_A-Za-z][A-Za-z0-9_]* {tokenFile<<"<ID, "<<yytext<<"> ";;}
"+"|"-" {tokenFile<<"<ADDOP, "<<yytext<<"> ";}
"/"|"*"/"%" {tokenFile<<"<MULOP, "<<yytext<<"> ";}
"=" {tokenFile<<"<ASSIGNOP, "<<yytext<<"> ";}
"&&"|"||" {tokenFile<<"<LOGICOP, "<<yytext<<"> ";}
"(" {tokenFile<<"<LPAREN, "<<yytext<<"> ";}
")" {tokenFile<<"<RPAREN, "<<yytext<<"> ";}
"!" {tokenFile<<"<NOT, "<<yytext<<"> ";}
"++"|"--" {tokenFile<<"<INCOP, "<<yytext<<"> ";}
"<"|"<="|">"|">="|"=="|"!=" {tokenFile<<"<RELOP, "<<yytext<<"> ";}
"[" {tokenFile<<"<LTHIRD, "<<yytext<<"> ";}
"]" {tokenFile<<"<RTHIRD, "<<yytext<<"> ";}
"," {tokenFile<<"<COMMA, "<<yytext<<"> ";}
";" {tokenFile<<"<SEMICOLON, "<<yytext<<"> ";}
"{" {tokenFile<<"<LCURL, "<<yytext<<"> ";}
"}" {tokenFile<<"<RCURL, "<<yytext<<"> ";}
["] {textStr = ""; BEGIN STR_STATE_1;}
<STR_STATE_1>[^"\\\n] {textStr += yytext;}
<STR_STATE_1>[\\] {BEGIN STR_STATE_2;}
<STR_STATE_1>["] {tokenFile<<"<STRING, "<<textStr<<"> ";textStr=""; BEGIN INITIAL;}
<STR_STATE_1><<EOF>> {cout << "Error: Unfinished string\n"; BEGIN INITIAL;}
<STR_STATE_1>[\n] {BEGIN STR_STATE_ERROR;}
<STR_STATE_2>[\n] {BEGIN STR_STATE_1;}
<STR_STATE_2>[\r\n] {}
<STR_STATE_2>[0] {BEGIN STR_NULL_STATE;}
<STR_STATE_2>{special}|["] {textChar = getSpecial(yytext);textStr += textChar;textChar="";BEGIN STR_STATE_1;}
<STR_STATE_2>. {BEGIN STR_STATE_ERROR;}
<STR_NULL_STATE>[^"\n] {}
<STR_NULL_STATE>["] {tokenFile<<"<STRING, "<<textStr<<"> ";textStr=""; BEGIN INITIAL;}
<STR_NULL_STATE>[\n] {BEGIN STR_STATE_ERROR;}
<STR_STATE_ERROR>["] {cout << "Invalid string format\n"; BEGIN INITIAL;}
<STR_STATE_ERROR>[^"\n] {}
<STR_STATE_ERROR>[\n] {cout << "Invalid string format\n";}
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

 tokenFile.open("1805021_output.txt", ios::out);
 if(!tokenFile) {
  printf("Cannot open output file\n");
  return 0;
 }

 yyin = fin;
 yylex();
 fclose(yyin);
 tokenFile.close();
 return 0;
}
