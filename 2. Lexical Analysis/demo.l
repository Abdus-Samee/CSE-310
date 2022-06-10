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
 string textChar;
 string textComm;
 string textStr;
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
    else if(s == "\\") return pref+"\\";
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

digit [0-9]
keyword "if"|"else"|"for"|"while"|"do"|"break"|"int"|"float"|"double"|"void"|"return"|"switch"|"case"|"default"|"continue"
special [t|n|a|b|f|v|r|\|'|0]

%%
{keyword} {
   tokenFile<<"<"<<toUpperCase(yytext)<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <"<<toUpperCase(yytext)<<"> Lexeme "<<yytext<<" found\n";
}
{digit}+ {
   tokenFile<<"<CONST_INT, "<<yytext<<"> ";
   logFile<<"Line no "<<line_count<<": TOKEN <CONST_INT> Lexeme "<<yytext<<" found\n";
   string s(yytext);
   bool res = symbolTable.insert(s, "CONST_INT");
   if(res) symbolTable.printAllScopeTables(logFile);
   else logFile << s << " already exists in current ScopeTable\n";
}
{digit}*"."({digit}+|{digit}+[E][-]?{digit}+) {tokenFile<<"<CONST_FLOAT, "<<yytext<<"> ";}
{digit}+[E][-]?{digit}+ {tokenFile<<"<CONST_FLOAT, "<<yytext<<"> ";}
{digit}+[E][-]?{digit}+"."({digit}*|{digit}*[E][-]?{digit}+) {error_count++;cout<<"Ill formed number "<<yytext<<endl;}
{digit}*"."{digit}+([E][-]?[0-9]+)?("."{digit}*|"."{digit}*[E][-]?{digit}+) {error_count++;cout<<"Too many decimal points "<<yytext<<endl;}
' {textChar="";BEGIN CHAR_STATE_1;}
<CHAR_STATE_1>(\r\n|\n) {cout<<"Unterminated character '\n";error_count++;line_count++;BEGIN INITIAL;}
<CHAR_STATE_1>[^\'\\.] {textChar = yytext;BEGIN CHAR_STATE_2;}
<CHAR_STATE_1>' {cout<<"Error: Empty character constant\n";error_count++;BEGIN INITIAL;}
<CHAR_STATE_1>[\\] {BEGIN CHAR_STATE_3;}
<CHAR_STATE_2>(\r\n|\n) {cout<<"Unterminated character '"<<isSpecial(textChar)<<endl;error_count++;line_count++;BEGIN INITIAL;}
<CHAR_STATE_2>[^\'] {cout << "Error: Multi character constant\n";error_count++;BEGIN CHAR_STATE_ERROR;}
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
<CHAR_STATE_2><<EOF>> {cout<<"Unterminated character '"<<isSpecial(textChar)<<endl;error_count++;BEGIN INITIAL;}
<CHAR_STATE_3>' {cout<<"Unterminated character '\\'\n";error_count++;BEGIN INITIAL;}
<CHAR_STATE_3>{special} {textChar = getSpecial(yytext); BEGIN CHAR_STATE_2;}
<CHAR_STATE_3>[^{special}] {cout<<"Unrecognized character\n";error_count++;BEGIN CHAR_STATE_ERROR;}
<CHAR_STATE_ERROR>' {textChar=""; BEGIN INITIAL;}
<CHAR_STATE_ERROR>(\r\n|\n) {cout<<"Unterminated character '\n";error_count++;line_count++;BEGIN INITIAL;}
<CHAR_STATE_ERROR>[^\'] {cout << "Error: Multi character constant\n";error_count++;}
<CHAR_STATE_ERROR><<EOF>> {cout<<"Unterminated character '\n";error_count++;BEGIN INITIAL;}
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
"/"|"*"/"%" {
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
["] {textStr = ""; BEGIN STR_STATE_1;}
<STR_STATE_1>[^"\\\n] {textStr += yytext;}
<STR_STATE_1>[\\] {BEGIN STR_STATE_2;}
<STR_STATE_1>["] {
   tokenFile<<"<STRING, "<<textStr<<"> ";
   string s = formatStringForLog(textStr);
   logFile<<"Line no "<<line_count<<": TOKEN <STRING> Lexeme "<<s<<" found\n";
   bool res = symbolTable.insert(s, "ID");
   if(res) symbolTable.printAllScopeTables(logFile);
   else logFile << s << " already exists in current ScopeTable\n";
   textStr=""; 
   BEGIN INITIAL;
}
<STR_STATE_1><<EOF>> {cout<<"Unterminated string \""<<textStr<<endl;error_count++;BEGIN INITIAL;}
<STR_STATE_1>(\r\n|\n) {cout<<"Unterminated string \""<<textStr<<endl;error_count++;line_count++;BEGIN INITIAL;}
<STR_STATE_2>[\n] {line_count++;BEGIN STR_STATE_1;}
<STR_STATE_2>[\r] {}
<STR_STATE_2>[0] {BEGIN STR_NULL_STATE;}
<STR_STATE_2>{special}|["] {textChar = getSpecial(yytext);textStr += textChar;textChar="";BEGIN STR_STATE_1;}
<STR_STATE_2>. {error_count++;BEGIN STR_STATE_ERROR;}
<STR_NULL_STATE>[^"\n] {}
<STR_NULL_STATE>["] {
   tokenFile<<"<STRING, "<<textStr<<"> ";
   string s = formatStringForLog(textStr);
   logFile<<"Line no "<<line_count<<": TOKEN <STRING> Lexeme "<<s<<" found\n";
   bool res = symbolTable.insert(s, "ID");
   if(res) symbolTable.printAllScopeTables(logFile);
   else logFile << s << " already exists in current ScopeTable\n";
   textStr=""; 
   BEGIN INITIAL;
}
<STR_NULL_STATE>[\n] {line_count++;error_count++;BEGIN STR_STATE_ERROR;}
<STR_STATE_ERROR>["] {cout << "Invalid string format\n"; BEGIN INITIAL;}
<STR_STATE_ERROR>[^"\n] {}
<STR_STATE_ERROR>[\n] {line_count++;error_count++;cout << "Invalid string format\n";}
<STR_STATE_ERROR><<EOF>> {cout << "Invalid string format\n";error_count++;BEGIN INITIAL;}
"//" {textComm="//";BEGIN COMMENT_STATE_1;}
<COMMENT_STATE_1>(\\\n|\\\r\n) {textComm+="\\";line_count++;}
<COMMENT_STATE_1>[\n] {
   logFile<<"Line no "<<line_count<<": TOKEN <STRING> Lexeme "<<textComm<<" found\n";
   textComm=""; 
   line_count++;
   BEGIN INITIAL;
}
<COMMENT_STATE_1>. {textComm+=yytext;}
"/*" {textComm="/*";BEGIN COMMENT_STATE_2;}
<COMMENT_STATE_2>"*/" {
   textComm += "*/";
   logFile<<"Line no "<<line_count<<": TOKEN <STRING> Lexeme "<<textComm<<" found\n";
   textComm=""; 
   BEGIN INITIAL;
}
<COMMENT_STATE_2>(\\\n|\\\r\n) {textComm+="\\";line_count++;}
<COMMENT_STATE_2>. {textComm+=yytext;}
<COMMENT_STATE_2><<EOF>> {cout << "Error: Unfinished comment\n";error_count++;BEGIN INITIAL;}
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
 logFile.open("1805021_log.txt", ios::out);

 if(!tokenFile) {
  printf("Cannot open output file\n");
  return 0;
 }

 yyin = fin;
 yylex();
 fclose(yyin);
 tokenFile.close();
 logFile.close();

 cout << "Total lines: " << line_count << endl;
 cout << "Total errors: " << error_count << endl;
 return 0;
}
