%{
 #include <bits/stdc++.h>
 #include "1805021_SymbolTable.h"
 
 extern FILE *yyin;

 int line_count = 1;
 int error_count = 0;

 #define BUCKETS 7

 void yyerror(char *s){
     printf("%s\n",s);
 }

 int yylex(void);

 fstream logFile;
 SymbolTable symbolTable(BUCKETS);

 vector<string> splitString (string str, char seperator)  
 {  
    vector<string> outputArray;
    stringstream streamData(str);
    string val;

    while (getline(streamData, val, seperator)) {
        outputArray.push_back(val);
    }

    return outputArray;
 }  

%}

%union{
    SymbolInfo* si;
}

%token<si> ADDOP ID MULOP CONST_INT CONST_FLOAT CONST_CHAR
%token IF ELSE WHILE FOR NUMBER INT FLOAT VOID PRINTLN RETURN
%token NOT ASSIGNOP RELOP LPAREN RPAREN COMMA SEMICOLON LOGICOP INCOP DECOP LCURL RCURL LTHIRD RTHIRD

%type<si> start program unit func_declaration func_definition
%type<si> parameter_list var_declaration type_specifier declaration_list argument_list arguments
%type<si> compound_statement statements statement expression_statement
%type<si> variable expression logic_expression rel_expression simple_expression term unary_expression factor

// Precedence: LOWER_THAN_ELSE < ELSE. Higher precedence, lower position
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%
start: program{
   $$ = $1;
   logFile << "Line " << line_count << ": start: program\n" << $$->getName() << endl; 
};

program: program unit   {
        $$ = new SymbolInfo($1->getName()+"\n"+$2->getName(), "program");
        logFile << "Line " << line_count << ": program: program unit\n" << $$->getName() << endl;
    }
    | unit  {
        $$ = $1;
        logFile << "Line " << line_count << ": program: unit\n" << $$->getName() << endl;
    }
    ;

unit: var_declaration   {
        $$ = $1;
        logFile << "Line " << line_count << ": unit: var_declaration\n" << $$->getName() << endl;
    }
    | func_declaration  {
        $$ = new SymbolInfo($1->getName(), "unit");
        logFile << "Line " << line_count << ": unit: func_declaration\n" << $$->getName() << endl;
    }
    | func_definition   {
        $$ = new SymbolInfo($1->getName(), "unit");
        logFile << "Line " << line_count << ": unit: func_definition\n" << $$->getName() << endl;
    }
    ;

func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON  {
        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+"("+$4->getName()+");", "func_declaration");
        logFile << "Line " << line_count << ": func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n" << $$->getName() << endl;
    }
    | type_specifier ID LPAREN RPAREN SEMICOLON {
        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+"();", "func_declaration");
        logFile << "Line " << line_count << ": func_declaration: type_specifier ID LPAREN RPAREN SEMICOLON\n" << $$->getName() << endl;
    }
    ;

func_definition: type_specifier ID LPAREN parameter_list RPAREN compound_statement  { 
        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+"("+$4->getName()+")"+$6->getName(), "func_definition");
        logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN parameter_list RPAREN compound_statement\n" << $$->getName() << endl;    
    }
    | type_specifier ID LPAREN RPAREN compound_statement    { 
        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+"()"+$5->getName(), "func_definition");
        logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN RPAREN compound_statement\n" << $$->getName() << endl;        
    }
    ;

parameter_list: parameter_list COMMA type_specifier ID  {
        $$ = new SymbolInfo($1->getName()+","+$3->getName()+" "+$4->getName(), "parameter_list");
        logFile << "Line " << line_count << ": parameter_list: parameter_list COMMA type_specifier ID\n" << $$->getName() << endl;
    }
    | parameter_list COMMA type_specifier   {
        $$ = new SymbolInfo($1->getName()+","+$3->getName(), "parameter_list");
        logFile << "Line " << line_count << ": parameter_list: parameter_list COMMA type_specifier\n" << $$->getName() << endl;
    }
    | type_specifier ID {
        $$ = new SymbolInfo($1->getName()+" "+$2->getName(), "parameter_list");
        logFile << "Line " << line_count << ": parameter_list: type_specifier ID\n" << $$->getName() << endl;
    }
    | type_specifier    {
        $$ = new SymbolInfo($1->getName(), "parameter_list");
        logFile << "Line " << line_count << ": parameter_list: type_specifier\n" << $$->getName() << endl;
    }
    ;

compound_statement: LCURL statements RCURL  {
        symbolTable.exitScope();
        $$ = new SymbolInfo("{"+$2->getName()+"}", "compound_statement");
        logFile << "Line " << line_count << ": compound_statement: LCURL statements RCURL\n" << $$->getName() << endl;
    }
    | LCURL RCURL   {
        symbolTable.exitScope();
        $$ = new SymbolInfo("{}", "compound_statement");
        logFile << "Line " << line_count << ": compound_statement: LCURL RCURL\n" << $$->getName() << endl;
    }
    ;

var_declaration: type_specifier declaration_list SEMICOLON  {
        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+";", "var_declaration");
        vector<string> splitted = splitString($2->getName(), ',');
        logFile << "Line " << line_count << ": type_specifier declaration_list : declaration_list COMMA ID\n" << $2->getName() << endl;
    }
    ;

type_specifier: INT { 
        $$ = new SymbolInfo("int", "int");
        logFile << "Line " << line_count << ": type_specifier : INT\nint\n"; 
    }
    | FLOAT { 
        $$ = new SymbolInfo("float", "float");
        logFile << "Line " << line_count << ": type_specifier : FLOAT\nfloat\n"; 
    }
    | VOID  { 
        $$ = new SymbolInfo("void", "void");
        logFile << "Line " << line_count << ": type_specifier : VOID\nvoid\n"; 
    }
    ;

declaration_list: declaration_list COMMA ID {
        $$ = new SymbolInfo($1->getName()+","+$3->getName(), "declaration_list");
        logFile << "Line " << line_count << ": declaration_list : declaration_list COMMA ID\n" << $$->getName() << endl;
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
        $$ = new SymbolInfo($1->getName()+","+$3->getName()+"["+$5->getName()+"]", "declaration_list");
        logFile << "Line " << line_count << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n" << $$->getName() << endl;
    }
    | ID    {
        $$ = new SymbolInfo($1->getName(), "ID");
        logFile << "Line " << line_count << ": declaration_list : ID\n" << $1->getName() << endl;
    }
    | ID LTHIRD CONST_INT RTHIRD    {
        $$ = new SymbolInfo($1->getName()+"["+$3->getName()+"]", "ID");
        logFile << "Line " << line_count << ": declaration_list : ID LTHIRD CONST_INT RTHIRD\n" << $1->getName() << endl;
    }
    ;

statements: statement   {
        $$ = new SymbolInfo($1->getName(), "statements");
        logFile << "Line " << line_count << ": statements : statement\n" << $$->getName() << endl;
    }
    | statements statement  {
        $$ = new SymbolInfo($1->getName()+"\n"+$2->getName(), "statements");
        logFile << "Line " << line_count << ": statements : statements statement\n" << $$->getName() << endl;
    }
    ;

statement: var_declaration  {
        $$ = new SymbolInfo($1->getName(), "statement");
        logFile << "Line " << line_count << ": statement : var_declaration\n" << $$->getName() << endl;
    }
    | expression_statement  {
        $$ = new SymbolInfo($1->getName(), "statement");
        logFile << "Line " << line_count << ": statement : expression_statement\n" << $$->getName() << endl;
    }
    | compound_statement    {
        $$ = new SymbolInfo($1->getName(), "statement");
        logFile << "Line " << line_count << ": statement : compound_statement\n" << $$->getName() << endl;
    }
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement  {
        $$ = new SymbolInfo("for("+$3->getName()+" "+$4->getName()+" "+$5->getName()+") "+$7->getName(), "statement");
        logFile << "Line " << line_count << ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n" << $$->getName() << endl;
    }
    | IF LPAREN expression RPAREN expression    %prec LOWER_THAN_ELSE   {
        $$ = new SymbolInfo("if("+$3->getName()+") "+$5->getName(), "statement");
        logFile << "Line " << line_count << ": statement : IF LPAREN expression RPAREN expression\n" << $$->getName() << endl;
    }
    | IF LPAREN expression RPAREN expression ELSE statement {
        $$ = new SymbolInfo("if("+$3->getName()+") "+$5->getName()+" else "+$7->getName(), "statement");
        logFile << "Line " << line_count << ": statement : IF LPAREN expression RPAREN expression ELSE statement\n" << $$->getName() << endl;
    }
    | WHILE LPAREN expression RPAREN statement  {
        $$ = new SymbolInfo("while("+$3->getName()+") "+$5->getName(), "statement");
        logFile << "Line " << line_count << ": statement : WHILE LPAREN expression RPAREN statement\n" << $$->getName() << endl;
    }
    | PRINTLN LPAREN ID RPAREN SEMICOLON    {
        $$ = new SymbolInfo("println("+$3->getName()+")", "statement");
        logFile << "Line " << line_count << ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n" << $$->getName() << endl;
    }
    | RETURN expression SEMICOLON   {
        $$ = new SymbolInfo("return "+$2->getName(), "statement");
        logFile << "Line " << line_count << ": statement : RETURN expression SEMICOLON\n" << $$->getName() << endl;
    }
    ;

expression_statement: SEMICOLON {
        $$ = new SymbolInfo(";", "expression_statement");
        logFile << "Line " << line_count << ": expression_statement : SEMICOLON\n;\n";
    }
    | expression SEMICOLON  {
        $$ = new SymbolInfo($1->getName()+";", "expression_statement");
        logFile << "Line " << line_count << ": expression_statement : expression SEMICOLON\n" << $$->getName() << endl;
    }
    ;

variable: ID    { 
        $$ = new SymbolInfo($1->getName(), "variable");
        logFile << "Line " << line_count << ": variable : ID\n" << $$->getName() << endl; 
    }
    | ID LTHIRD expression RTHIRD   { 
        $$ = new SymbolInfo($1->getName()+"["+$3->getName()+"]", "variable");
        logFile << "Line " << line_count << ": variable : ID LTHIRD expression RTHIRD\n" << $$->getName() << endl; 
    }
    ;

expression: logic_expression    {
        $$ = new SymbolInfo($1->getName(), "expression");
        logFile << "Line " << line_count << ": expression : logic_expression\n" << $$->getName() << endl;
    }
    | variable ASSIGNOP logic_expression    {
        $$ = new SymbolInfo($1->getName()+"="+$3->getName(), "expression");
        logFile << "Line " << line_count << ": expression : variable ASSIGNOP logic_expression\n" << $$->getName() << endl;
    }
    ;

logic_expression: rel_expression    {
        $$ = new SymbolInfo($1->getName(), "logic_expression");
        logFile << "Line " << line_count << ": logic_expression : rel_expression\n" << $$->getName() << endl;
    }
    | rel_expression LOGICOP rel_expression {
        $$ = new SymbolInfo($1->getName()+yylval.si->getName()+$3->getName(), "logic_expression");
        logFile << "Line " << line_count << ": logic_expression : rel_expression LOGICOP rel_expression\n" << $$->getName() << endl;
    }
    ;

rel_expression: simple_expression   {
        $$ = new SymbolInfo($1->getName(), "rel_expression");
        logFile << "Line " << line_count << ": rel_expression : simple_expression\n" << $$->getName() << endl;
    }
    | simple_expression RELOP simple_expression {
        $$ = new SymbolInfo($1->getName()+yylval.si->getName()+$3->getName(), "rel_expression");
        logFile << "Line " << line_count << ": rel_expression : simple_expression RELOP simple_expression\n" << $$->getName() << endl;
    }
    ;

simple_expression: term {
        $$ = new SymbolInfo($1->getName(), "simple_expression");
        logFile << "Line " << line_count << ": simple_expression : term\n" << $$->getName() << endl;
    }
    | simple_expression ADDOP term  {
        $$ = new SymbolInfo($1->getName()+yylval.si->getName()+$3->getName(), "simple_expression");
        logFile << "Line " << line_count << ": simple_expression : simple_expression ADDOP term\n" << $$->getName() << endl;
    }
    ;

term: unary_expression  {
        $$ = new SymbolInfo($1->getName(), "term");
        logFile << "Line " << line_count << ": term : unary_expression\n" << $$->getName() << endl;
    }
    | term MULOP unary_expression   {
        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), "term");
        logFile << "Line " << line_count << ": term : term MULOP unary_expression\n" << $$->getName() << endl;
    }
    ;

unary_expression: ADDOP unary_expression    {
        $$ = new SymbolInfo(yylval.si->getName()+$2->getName(), "unary_expression");
        logFile << "Line " << line_count << ": unary_expression : ADDOP unary_expression\n" << $$->getName() << endl;
    }
    | NOT unary_expression  {
        $$ = new SymbolInfo("!"+$2->getName(), "unary_expression");
        logFile << "Line " << line_count << ": unary_expression : NOT unary_expression\n" << $$->getName() << endl;
    }
    | factor    {
        $$ = new SymbolInfo($1->getName(), "unary_expression");
        logFile << "Line " << line_count << ": unary_expression : factor\n" << $$->getName() << endl;
    }
    ;

factor: variable    {
        $$ = new SymbolInfo($1->getName(), "factor");
        logFile << "Line " << line_count << ": factor : variable\n" << $$->getName() << endl;
    }
    | ID LPAREN argument_list RPAREN    { 
        $$ = new SymbolInfo($1->getName()+"("+$3->getName()+")", "factor");
        logFile << "Line " << line_count << ": factor : ID LPAREN argument_list RPAREN\n" << $$->getName() << endl;
    }
    | LPAREN expression RPAREN  {
        $$ = new SymbolInfo("("+$2->getName()+")", "factor");
        logFile << "Line " << line_count << ": factor : LPAREN expression RPAREN\n" << $$->getName() << endl;
    }
    | CONST_INT { 
        $$ = yylval.si;
        logFile << "Line " << line_count << ": factor : CONST_INT\n" << $$->getName() << endl;
     }
    | CONST_FLOAT   {
        $$ = yylval.si;
        logFile << "Line " << line_count << ": factor : CONST_FLOAT\n" << $$->getName() << endl;
    }
    | variable INCOP    {
        $$ = new SymbolInfo($1->getName()+"++", "factor");
        logFile << "Line " << line_count << ": factor : variable INCOP\n" << $$->getName() << endl;
    }
    | variable DECOP    {
        $$ = new SymbolInfo($1->getName()+"--", "factor");
        logFile << "Line " << line_count << ": factor : variable DECOP\n" << $$->getName() << endl;
    }
    ;

argument_list: arguments    {
        $$ = new SymbolInfo($1->getName(), "argument_list");
        logFile << "Line " << line_count << ": argument_list : arguments\n" << $$->getName() << endl;
    }
    |   {}
    ;

arguments: arguments COMMA logic_expression {
        $$ = new SymbolInfo($1->getName()+","+$3->getName(), "arguments");
        logFile << "Line " << line_count << ": arguments : arguments COMMA logic_expression\n" << $$->getName() << endl;
    }
    | logic_expression  {
        $$ = new SymbolInfo($1->getName(), "arguments");
        logFile << "Line " << line_count << ": arguments : logic_expression\n" << $$->getName() << endl;
    }
    ;

%%

main(int argc, char* argv[], char* endp[])
{
    if(argc != 2){
        printf("Please provide input file name!\n");
        exit(1);
    }

    FILE* fin = fopen(argv[1], "r");
    if(fin == NULL){
        printf("Cannot open specified file\n");
        exit(1);
    }

    logFile.open("1805021_log.txt", ios::out);

    yyin = fin;
    yyparse();
    fclose(yyin);

    logFile.close();

    exit(0);
}
