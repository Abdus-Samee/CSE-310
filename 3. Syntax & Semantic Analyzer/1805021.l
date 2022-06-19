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
 #include "1805021_SymbolInfo.h"
 #include "y.tab.h"

 using namespace std;

 extern int line_count;
 extern int error_count;
 
 int multi;
 string textChar;
 string textComm;
 string textStr;
 string textMulti;
 fstream tokenFile;

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
    else if(s == "\\") return s;
    else if(s == "\'") return pref+"\'";
    else if(s == "\0") return pref+"0";

   return s;
 }

 string formatStringForLog(string s, bool multi){
   string ans = "";
   for(int i = 0; i < s.length(); i++){
      string temp="";
      temp+=s[i];
      if(((temp == "\\") && (s[i+1]=='"')) || (temp=="\"")){
         string pref = "\\";
         ans += pref+"\"";
         i++;
      }
      else if(!multi) ans+=isSpecial(temp);
      else ans+=temp;
   }
   return ans;
 }

%}

DIGIT [0-9]
keyword "if"|"else"|"for"|"while"|"do"|"break"|"int"|"char"|"float"|"double"|"void"|"return"|"switch"|"case"|"default"|"continue"
special [t|n|a|b|f|v|r|\|'|0]

%%
{keyword} {
   string s = toUpperCase(yytext);
   if(s == "IF") return IF;
   else if(s == "ELSE") return ELSE;
   else if(s == "FOR") return FOR;
   else if(s == "WHILE") return WHILE;
   else if(s == "INT") return INT;
   else if(s == "FLOAT") return FLOAT;
   else if(s == "VOID") return VOID;
   else if(s == "RETURN") return RETURN;
}

{DIGIT}+ {
   string s = yytext;
   yylval.si = new SymbolInfo(s, "CONST_INT");
   return CONST_INT;
}

{DIGIT}+[^\]".""E""+""-""/""*""%""=""+=""-=""*=""/=""%=""&&""||""("")""{""}""["","";"\n\r ]+ {
   error_count++;
}

{DIGIT}*"."({DIGIT}+|{DIGIT}+[E][-]?{DIGIT}+) {
   string s = yytext;
   yylval.si = new SymbolInfo(s, "CONST_FLOAT");
   return CONST_FLOAT;
}

{DIGIT}+[E][-]?{DIGIT}+ {
   string s = yytext;
   yylval.si = new SymbolInfo(s, "CONST_FLOAT");
   return CONST_FLOAT;
}

{DIGIT}+[E][-]?{DIGIT}+"."({DIGIT}*|{DIGIT}*[E][-]?{DIGIT}+) {
   error_count++;
}

{DIGIT}*"."{DIGIT}+([E][-]?[0-9]+)?("."{DIGIT}*|"."{DIGIT}*[E][-]?{DIGIT}+) {
   error_count++;
}

' {
   textChar="";
   BEGIN CHAR_STATE_1;
}

<CHAR_STATE_1>(\r\n|\n) {
   error_count++;
   line_count++;
   textChar="";
   BEGIN INITIAL;
}

<CHAR_STATE_1>[^\'\\.] {
   textChar += yytext;
   BEGIN CHAR_STATE_2;
}

<CHAR_STATE_1>' {
   error_count++;
   BEGIN INITIAL;
}

<CHAR_STATE_1>[\\] {BEGIN CHAR_STATE_3;}

<CHAR_STATE_1><<EOF>> {
   error_count++;
   textChar="";
   BEGIN INITIAL;
}

<CHAR_STATE_2>(\r\n|\n) {
   error_count++;
   line_count++;
   BEGIN INITIAL;
}

<CHAR_STATE_2>[^\'] {
   textChar += yytext;
   BEGIN CHAR_STATE_ERROR;
}

<CHAR_STATE_2>' {
   string s = isSpecial(textChar);
   textChar=""; 
   yylval.si = new SymbolInfo(s, "CONST_CHAR");
   return CONST_CHAR;
   /*BEGIN INITIAL;*/
}

<CHAR_STATE_2><<EOF>> {
   error_count++;
   BEGIN INITIAL;
}

<CHAR_STATE_3>' {
   error_count++;
   BEGIN INITIAL;
}

<CHAR_STATE_3>{special} {
   textChar = getSpecial(yytext); 
   BEGIN CHAR_STATE_2;
}

<CHAR_STATE_ERROR>(\r\n|\n) {
   error_count++;
   line_count++;
   textChar="";
   BEGIN INITIAL;
}

<CHAR_STATE_ERROR><<EOF>> {
   error_count++;
   textChar="";
   BEGIN INITIAL;
}

<CHAR_STATE_ERROR>[^\'] {textChar += yytext;}

<CHAR_STATE_ERROR>' {
   error_count++;
   textChar="";
   BEGIN INITIAL;
}

[_A-Za-z][A-Za-z0-9_]* {
   yylval.si = new SymbolInfo(yytext, "ID");
   return ID;
}

"+"|"-" { 
   yylval.si = new SymbolInfo(yytext, "ADDOP");
   return ADDOP; 
}

"/"|"*"|"%" { 
   yylval.si = new SymbolInfo(yytext, "MULOP");
   return MULOP;
 }

"=" { return ASSIGNOP; }

"&&"|"||" { 
   yylval.si = new SymbolInfo(yytext, "LOGICOP");
   return LOGICOP;
 }

"(" { return LPAREN; }

")" { return RPAREN; }

"!" { return NOT; }

"++" { return INCOP; }

"--" { return DECOP; }

"<"|"<="|">"|">="|"=="|"!=" { 
   yylval.si = new SymbolInfo(yytext, "RELOP");
   return RELOP;
 }

"[" { return LTHIRD; }

"]" { return RTHIRD; }

"," { return COMMA; }

";" { return SEMICOLON; }

"{" { return LCURL; }

"}" { return RCURL; }

["] {textStr = "";textMulti="";multi=0;BEGIN STR_STATE_1;}

<STR_STATE_1>[^"\\\n] {textStr += yytext;textMulti+=yytext;}

<STR_STATE_1>[\\] {BEGIN STR_STATE_2;}

<STR_STATE_1>["] {
   tokenFile<<"<STRING, \""<<textStr<<"\"> ";
   string s;
   if(!multi) s = formatStringForLog(textStr, false);
   else s = formatStringForLog(textMulti, true);
   textStr=""; 
   BEGIN INITIAL;
}

<STR_STATE_1><<EOF>> {
   error_count++;
   textStr="";
   textMulti="";
   BEGIN INITIAL;
}

<STR_STATE_1>(\r\n|\n) {
   error_count++;
   line_count++;
   textStr="";
   textMulti="";
   BEGIN INITIAL;
}

<STR_STATE_2>(\n|\r\n) {
   multi++;
   line_count++;
   textMulti=textStr;
   textMulti += "\\\n";
   BEGIN STR_STATE_1;
}

<STR_STATE_2>[0] {BEGIN STR_NULL_STATE;}

<STR_STATE_2>{special} {
   textChar = getSpecial(yytext);
   textStr += textChar;
   textMulti+=textChar;
   textChar="";
   BEGIN STR_STATE_1;
}

<STR_STATE_2>["] {
   textChar = "\\\"";
   textStr += "\"";
   textMulti += textChar;
   textChar="";
   BEGIN STR_STATE_1;
}

<STR_STATE_2>. {
   error_count++;
   textStr+="\\";
   textStr+=yytext;
   BEGIN STR_STATE_ERROR;
}

<STR_NULL_STATE>[^"\n] {}

<STR_NULL_STATE>["] {
   tokenFile<<"<STRING, \""<<textStr<<"\"> ";
   string s;
   if(multi) s = formatStringForLog(textStr, true);
   else s = formatStringForLog(textStr, false);
   textStr=""; 
   BEGIN INITIAL;
}

<STR_NULL_STATE>(\\\n|\\\r\n) {}

<STR_NULL_STATE>[\n] {
   line_count++;
   error_count++;
   BEGIN STR_STATE_ERROR;
}

<STR_STATE_ERROR>["] {
   BEGIN INITIAL;
}

<STR_STATE_ERROR>[^"\n] {textStr+=yytext;}

<STR_STATE_ERROR>[\n] {
   error_count++;
   line_count++;
   textStr="";
   BEGIN INITIAL;
}

<STR_STATE_ERROR><<EOF>> {
   error_count++;
   BEGIN INITIAL;
}

"//" {
   textComm="//";
   BEGIN COMMENT_STATE_1;
}

<COMMENT_STATE_1>(\\\n|\\\r\n) {
   textComm+="\\\n";
   line_count++;
}

<COMMENT_STATE_1>(\n|\r\n) {
   textComm=""; 
   line_count++;
   BEGIN INITIAL;
}

<COMMENT_STATE_1>. {textComm+=yytext;}
"/*" {
   textComm="/*";
   multi=0;
   BEGIN COMMENT_STATE_2;
}

<COMMENT_STATE_2>"*/" {
   textComm += "*/";
   textComm=""; 
   multi=0;
   BEGIN INITIAL;
}

<COMMENT_STATE_2>(\\\n|\\\r\n) {
   textComm+="\\";
   multi++;
   line_count++;
}

<COMMENT_STATE_2>(\n|\r\n) {
   multi++;
   line_count++;
}

<COMMENT_STATE_2>[^ \t\f\r\v] {textComm+=yytext;}

<COMMENT_STATE_2>[ \t\f\r\v] {}

<COMMENT_STATE_2><<EOF>> {
   error_count++;
   multi=0;
   BEGIN INITIAL;
}

(\n|\r\n) {
   line_count++;
}

[ \t\f\r\v]+ {}

. {
   error_count++;
}

%%
