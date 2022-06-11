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
 int error_count = 0;
 int multi;
 string textChar;
 string textComm;
 string textStr;
 string textMulti;
 fstream tokenFile;
 fstream logFile;
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
    else if(s == "\\") return s;
    else if(s == "\'") return pref+"\'";
    else if(s == "\0") return pref+"0";

   return s;
 }

 string formatStringForLog(string s){
   string ans = "";
   for(int i = 0; i < s.length(); i++){
      string temp="";
      temp+=s[i];
      ans+=isSpecial(temp);
   }
   return ans;
 }

%}

DIGIT [0-9]
keyword "if"|"else"|"for"|"while"|"do"|"break"|"int"|"char"|"float"|"double"|"void"|"return"|"switch"|"case"|"default"|"continue"
special [t|n|a|b|f|v|r|\|'|0]

%%
{keyword} {
   tokenFile<<"<"<<toUpperCase(yytext)<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <"<<toUpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
}
{DIGIT}+ {
   tokenFile<<"<CONST_INT, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <CONST_INT> Lexeme "<<yytext<<" found\n";
   string s(yytext);
   bool res = symbolTable.insert(s, "CONST_INT");
   if(res) symbolTable.printAllScopeTables(logFile);
   else logFile << s << " already exists in current ScopeTable\n";
}
{DIGIT}+[^".""E"\n","";" ]+ {
   error_count++;
   logFile<<"Error at line no "<<line_count<<" : Invalid prefix on ID or invalid suffix on Number "<<yytext<<"\n";
}
{DIGIT}*"."({DIGIT}+|{DIGIT}+[E][-]?{DIGIT}+) {
   tokenFile<<"<CONST_FLOAT, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <CONST_FLOAT> Lexeme "<<yytext<<" found\n";
   string s(yytext);
   bool res = symbolTable.insert(s, "CONST_FLOAT");
   if(res) symbolTable.printAllScopeTables(logFile);
   else logFile << s << " already exists in current ScopeTable\n";
}
{DIGIT}+[E][-]?{DIGIT}+ {
   tokenFile<<"<CONST_FLOAT, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <CONST_FLOAT> Lexeme "<<yytext<<" found\n";
   string s(yytext);
   bool res = symbolTable.insert(s, "CONST_FLOAT");
   if(res) symbolTable.printAllScopeTables(logFile);
   else logFile << s << " already exists in current ScopeTable\n";
}
{DIGIT}+[E][-]?{DIGIT}+"."({DIGIT}*|{DIGIT}*[E][-]?{DIGIT}+) {
   error_count++;
   logFile<<"Error at line no "<<line_count<<": Ill formed number "<<yytext<<endl;
}
{DIGIT}*"."{DIGIT}+([E][-]?[0-9]+)?("."{DIGIT}*|"."{DIGIT}*[E][-]?{DIGIT}+) {
   error_count++;
   logFile<<"Error at line no "<<line_count<<": Too many decimal points "<<yytext<<endl;
}
' {
   textChar="";
   BEGIN CHAR_STATE_1;
}
<CHAR_STATE_1>(\r\n|\n) {
   error_count++;
   logFile<<"Error at line no "<<line_count<<": Unterminated character '\n";
   line_count++;
   textChar="";
   BEGIN INITIAL;
}
<CHAR_STATE_1>[^\'\\.] {
   textChar += yytext;
   BEGIN CHAR_STATE_2;
}
<CHAR_STATE_1>' {
   logFile<<"Error at line no: "<<line_count<<": Empty character constant error ''\n";
   error_count++;
   BEGIN INITIAL;
}
<CHAR_STATE_1>[\\] {BEGIN CHAR_STATE_3;}
<CHAR_STATE_1><<EOF>> {
   error_count++;
   logFile<<"Error at line no "<<line_count<<": Unterminated character '\n";
   textChar="";
   BEGIN INITIAL;
}
<CHAR_STATE_2>(\r\n|\n) {
   logFile<<"Error at line no "<<line_count<<": Unterminated character '"<<isSpecial(textChar)<<endl;
   error_count++;
   line_count++;
   BEGIN INITIAL;
}
<CHAR_STATE_2>[^\'] {
   textChar += yytext;
   BEGIN CHAR_STATE_ERROR;
}
<CHAR_STATE_2>' {
   textChar=(textChar==" "? "''":textChar);
   tokenFile<<"<CONST_CHAR, "<<textChar<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <CONST_CHAR> Lexeme '"<<isSpecial(textChar)<<"' found\n";
   string s(yytext);
   bool res = symbolTable.insert(s, "CONST_CHAR");
   if(res) symbolTable.printAllScopeTables(logFile);
   else logFile << s << " already exists in current ScopeTable\n";
   textChar=""; 
   BEGIN INITIAL;
}
<CHAR_STATE_2><<EOF>> {
   logFile<<"Error at line no "<<line_count<<": Unterminated character '"<<isSpecial(textChar)<<endl;
   error_count++;
   BEGIN INITIAL;
}
<CHAR_STATE_3>' {
   logFile<<"Error at line no "<<line_count<<": Unterminated character '\\'\n";
   error_count++;
   BEGIN INITIAL;
}
<CHAR_STATE_3>{special} {
   textChar = getSpecial(yytext); 
   BEGIN CHAR_STATE_2;
}
<CHAR_STATE_ERROR>(\r\n|\n) {
   logFile<<"Unterminated character '\n";
   error_count++;
   line_count++;
   BEGIN INITIAL;
}
<CHAR_STATE_ERROR><<EOF>> {
   logFile<<"Error at line no "<<line_count<<": Unterminated character '"<<textChar<<endl;
   error_count++;
   textChar="";
   BEGIN INITIAL;
}
<CHAR_STATE_ERROR>[^\'] {textChar += yytext;}
<CHAR_STATE_ERROR>' {
   logFile<<"Error at line no "<<line_count<<": Multi character constant error '"<<textChar<<"'\n";
   error_count++;
   textChar="";
   BEGIN INITIAL;
}
[_A-Za-z][A-Za-z0-9_]* {
   tokenFile<<"<ID, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <ID> Lexeme "<<yytext<<" found\n";
   string s(yytext);
   bool res = symbolTable.insert(s, "ID");
   if(res) symbolTable.printAllScopeTables(logFile);
   else logFile << s << " already exists in current ScopeTable\n";
}
"+"|"-" {
   tokenFile<<"<ADDOP, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <ADDOP> Lexeme "<<yytext<<" found\n";
}
"/"|"*"|"%" {
   tokenFile<<"<MULOP, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <MULOP> Lexeme "<<yytext<<" found\n";
}
"=" {
   tokenFile<<"<ASSIGNOP, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <ASSIGNOP> Lexeme "<<yytext<<" found\n";
   }
"&&"|"||" {
   tokenFile<<"<LOGICOP, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <LOGICOP> Lexeme "<<yytext<<" found\n";
   }
"(" {
   tokenFile<<"<LPAREN, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <LPAREN> Lexeme "<<yytext<<" found\n";
}
")" {
   tokenFile<<"<RPAREN, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <RPAREN> Lexeme "<<yytext<<" found\n";
}
"!" {
   tokenFile<<"<NOT, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <NOT> Lexeme "<<yytext<<" found\n";
}
"++"|"--" {
   tokenFile<<"<INCOP, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <INCOP> Lexeme "<<yytext<<" found\n";
}
"<"|"<="|">"|">="|"=="|"!=" {
   tokenFile<<"<RELOP, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <RELOP> Lexeme "<<yytext<<" found\n";
}
"[" {
   tokenFile<<"<LTHIRD, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <LTHIRD> Lexeme "<<yytext<<" found\n";
}
"]" {
   tokenFile<<"<RTHIRD, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <RTHIRD> Lexeme "<<yytext<<" found\n";
}
"," {
   tokenFile<<"<COMMA, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <COMMA> Lexeme "<<yytext<<" found\n";
}
";" {
   tokenFile<<"<SEMICOLON, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <SEMICOLON> Lexeme "<<yytext<<" found\n";
}
"{" {
   tokenFile<<"<LCURL, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <LCURL> Lexeme "<<yytext<<" found\n";
   symbolTable.enterScope();
}
"}" {
   tokenFile<<"<RCURL, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <RCURL> Lexeme "<<yytext<<" found\n";
   symbolTable.exitScope();
}
["] {textStr = "";textMulti="";multi=0;BEGIN STR_STATE_1;}
<STR_STATE_1>[^"\\\n] {textStr += yytext;textMulti+=yytext;}
<STR_STATE_1>[\\] {BEGIN STR_STATE_2;}
<STR_STATE_1>["] {
   tokenFile<<"<STRING, \""<<textStr<<"\"> ";
   string s;
   if(!multi) s = formatStringForLog(textStr);
   else s = textMulti;
   logFile<<"Line no "<<line_count<<": TOKEN <STRING> Lexeme \""<<s<<"\" found --> <STRING, \""<<textStr<<"\">\n";
   textStr=""; 
   BEGIN INITIAL;
}
<STR_STATE_1><<EOF>> {
   error_count++;
   if(!multi) logFile<<"Error at line no "<<line_count<<": Unterminated String \""<<formatStringForLog(textStr)<<endl;
   else logFile<<"Error at line no "<<line_count<<": Unterminated String \""<<textMulti<<"\n";
   textStr="";
   textMulti="";
   BEGIN INITIAL;
}
<STR_STATE_1>(\r\n|\n) {
   error_count++;
   if(!multi) logFile<<"Error at line no "<<line_count<<": Unterminated String \""<<formatStringForLog(textStr)<<"\n";
   else logFile<<"Error at line no "<<(line_count-multi)<<": Unterminated String \""<<textMulti<<"\n";
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
<STR_STATE_2>{special}|["] {
   textChar = getSpecial(yytext);
   textStr += textChar;
   textMulti+=textChar;
   textChar="";
   BEGIN STR_STATE_1;
}
<STR_STATE_2>. {
   error_count++;
   textStr+="\\";
   textStr+=yytext;
   logFile<<"Error at line no "<<line_count<<": Invalid escape sequence \\ \""<<textStr<<"\n";
   BEGIN STR_STATE_ERROR;
}
<STR_NULL_STATE>[^"\n] {}
<STR_NULL_STATE>["] {
   tokenFile<<"<STRING, \""<<textStr<<"\"> ";
   string s = formatStringForLog(textStr);
   logFile<<"Line no "<<line_count<<": TOKEN <STRING> Lexeme \""<<s<<"\" found --> <STRING, \""<<textStr<<"\">\n";
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
   logFile<<"Error at line no "<<line_count<<": Invalid String format \""<<textStr<<"\"\n"; 
   BEGIN INITIAL;
}
<STR_STATE_ERROR>[^"\n] {textStr+=yytext;}
<STR_STATE_ERROR>[\n] {
   error_count++;
   logFile<<"Error at line no "<<line_count<<": Unterminated String \""<<textStr<<endl;
   line_count++;
   textStr="";
   BEGIN INITIAL;
}
<STR_STATE_ERROR><<EOF>> {
   logFile<<"Error at line no "<<line_count<<": Unterminated String \""<<textStr<<endl;
   error_count++;
   BEGIN INITIAL;
}
"//" {
   textComm="//";
   BEGIN COMMENT_STATE_1;
}
<COMMENT_STATE_1>(\\\n|\\\r\n) {
   textComm+="\\";
   line_count++;
}
<COMMENT_STATE_1>(\n|\r\n) {
   logFile<<"Line no "<<line_count<<": TOKEN <COMMENT> Lexeme "<<textComm<<" found\n";
   textComm=""; 
   line_count++;
   BEGIN INITIAL;
}
<COMMENT_STATE_1>. {textComm+=yytext;}
"/*" {
   textComm="/*";
   BEGIN COMMENT_STATE_2;
}
<COMMENT_STATE_2>"*/" {
   textComm += "*/";
   logFile<<"Line no "<<line_count<<": TOKEN <COMMENT> Lexeme "<<textComm<<" found\n";
   textComm=""; 
   BEGIN INITIAL;
}
<COMMENT_STATE_2>(\\\n|\\\r\n) {textComm+="\\";line_count++;}
<COMMENT_STATE_2>(\n|\r\n) {textComm+="\n";line_count++;}
<COMMENT_STATE_2>. {textComm+=yytext;}
<COMMENT_STATE_2><<EOF>> {
   logFile<<"Error at line no "<<line_count<< ": Unterminated comment\n";
   error_count++;
   BEGIN INITIAL;
}
(\n|\r\n) {line_count++;}
[ \t\f\r\v]+ {}
. {
   error_count++;
   logFile<<"Error at line no "<<line_count<<": Unrecognized character "<<yytext<<"\n";
}
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
 logFile.open("1805021_log.txt", ios::out);

 if(!tokenFile) {
  printf("Cannot open output file\n");
  return 0;
 }

 yyin = fin;
 yylex();
 fclose(yyin);

 symbolTable.printAllScopeTables(logFile);
 logFile << "Total lines: " << line_count << endl;
 logFile << "Total errors: " << error_count << endl;

 tokenFile.close();
 logFile.close();
 return 0;
}
