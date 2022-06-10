%option noyywrap

%x CHAR_STATE_1
%x CHAR_STATE_2
%x CHAR_STATE_3
%x CHAR_STATE_ERROR
%x STR_STATE_1
%x STR_STATE_2
%x STR_NULL_STATE
%x STR_STATE_ERROR
%x COMMENT_STATE_1
%x COMMENT_STATE_2

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

 int line_count = 1;
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

 string isSpecial(string s){
    string pref = "\\";
    if(s == "\n") return pref+"n";
    else if(s == "\t") return pref+"t";
    else if(s == "\r") return pref+"r";
    else if(s == "\a") return pref+"a";
    else if(s == "\b") return pref+"b";
    else if(s == "\f") return pref+"f";
    else if(s == "\v") return pref+"v";
    else if(s == "\\") return pref+"\\";
    else if(s == "\'") return pref+"\'";
    else if(s == "\0") return pref+"0";

   return s;
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
' {textChar="";BEGIN CHAR_STATE_1;}
<CHAR_STATE_1>(\r\n|\n) {line_count++;cout<<"Unterminated character '\n";BEGIN INITIAL;}
<CHAR_STATE_1>[^\'\\.] {textChar = yytext;BEGIN CHAR_STATE_2;}
<CHAR_STATE_1>' {cout<<"Error: Empty character constant\n"; BEGIN INITIAL;}
<CHAR_STATE_1>[\\] {BEGIN CHAR_STATE_3;}
<CHAR_STATE_2>(\r\n|\n) {cout<<"Unterminated character '"<<isSpecial(textChar)<<endl; line_count++;BEGIN INITIAL;}
<CHAR_STATE_2>[^\'] {cout << "Error: Multi character constant\n"; BEGIN CHAR_STATE_ERROR;}
<CHAR_STATE_2>' {textChar=(textChar==" "? "''":textChar);tokenFile<<"<CONST_CHAR, "<<textChar<<"> ";textChar=""; BEGIN INITIAL;}
<CHAR_STATE_2><<EOF>> {cout<<"Unterminated character '"<<isSpecial(textChar)<<endl;BEGIN INITIAL;}
<CHAR_STATE_3>' {cout<<"Unterminated character '\\'\n";BEGIN INITIAL;}
<CHAR_STATE_3>{special} {textChar = getSpecial(yytext); BEGIN CHAR_STATE_2;}
<CHAR_STATE_3>[^{special}] {cout<<"Unrecognized character\n";BEGIN CHAR_STATE_ERROR;}
<CHAR_STATE_ERROR>' {textChar=""; BEGIN INITIAL;}
<CHAR_STATE_ERROR>(\r\n|\n) {cout<<"Unterminated character '\n";line_count++;BEGIN INITIAL;}
<CHAR_STATE_ERROR>[^\'] {cout << "Error: Multi character constant\n";}
<CHAR_STATE_ERROR><<EOF>> {cout<<"Unterminated character '\n";BEGIN INITIAL;}
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
<STR_STATE_1><<EOF>> {cout<<"Unterminated string \""<<textStr<<endl; BEGIN INITIAL;}
<STR_STATE_1>(\r\n|\n) {cout<<"Unterminated string \""<<textStr<<endl;line_count++;BEGIN INITIAL;}
<STR_STATE_2>[\n] {line_count++;BEGIN STR_STATE_1;}
<STR_STATE_2>[\r] {}
<STR_STATE_2>[0] {BEGIN STR_NULL_STATE;}
<STR_STATE_2>{special}|["] {textChar = getSpecial(yytext);textStr += textChar;textChar="";BEGIN STR_STATE_1;}
<STR_STATE_2>. {BEGIN STR_STATE_ERROR;}
<STR_NULL_STATE>[^"\n] {}
<STR_NULL_STATE>["] {tokenFile<<"<STRING, "<<textStr<<"> ";textStr=""; BEGIN INITIAL;}
<STR_NULL_STATE>[\n] {line_count++;BEGIN STR_STATE_ERROR;}
<STR_STATE_ERROR>["] {cout << "Invalid string format\n"; BEGIN INITIAL;}
<STR_STATE_ERROR>[^"\n] {}
<STR_STATE_ERROR>[\n] {line_count++;cout << "Invalid string format\n";}
<STR_STATE_ERROR><<EOF>> {cout << "Invalid string format\n"; BEGIN INITIAL;}
"//" {BEGIN COMMENT_STATE_1;}
<COMMENT_STATE_1>(\\\n|\\\r\n) {line_count++;}
<COMMENT_STATE_1>[\n] {line_count++;BEGIN INITIAL;}
<COMMENT_STATE_1>. {}
"/*" {BEGIN COMMENT_STATE_2;}
<COMMENT_STATE_2>"*/" {BEGIN INITIAL;}
<COMMENT_STATE_2>(\\\n|\\\r\n) {line_count++;}
<COMMENT_STATE_2>. {}
<COMMENT_STATE_2><<EOF>> {cout << "Error: Unfinished comment\n"; BEGIN INITIAL;}
(\n|\r\n) {line_count++;}
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

 cout << "Total lines: " << line_count << endl;
 return 0;
}
