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
 fstream errorFile;
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

 bool isVarArray(string s){
    regex arr_var("[_A-Za-z][A-Za-z0-9_]*\[[0-9]+\]");
    if(regex_match(s, arr_var)) return true;

    return false;
 }

 string getArrayName(string s){
    string ans = "";
    for(int i = 0; (i < s.length()) && (s[i] != '['); i++) ans += s[i];

    return ans;
 }

 string getArrayLength(string s){
    regex regexp("[0-9]+");
    smatch m;
    regex_search(s, m, regexp);
    string sz = "";
    for(auto x : m) sz += x;

    return sz;
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
        string type = $1->getType();
        SymbolInfo* var;

        $$ = new SymbolInfo($1->getName()+" "+$2->getName(), type);

        if(isVarArray($2->getName())){
            string name = getArrayName($2->getName());
            string len = getArrayLength($2->getName());
            var = new SymbolInfo(name, $1->getName());
            var->setArrayLength(len);
        }else{
            var = new SymbolInfo($2->getName(), $1->getName());
        }

        if(!symbolTable.insert(var)){
            error_count++;
            $$->setType("error");
            errorFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getName() << endl;
            logFile << "Line " << line_count << ": parameter_list: type_specifier ID\n";
            logFile << "Error at line " << line_count << ": Multiple declaration of " << $2->getName() << endl;
            logFile << $$->getName() << endl;
        }else{
            logFile << "Line " << line_count << ": parameter_list: type_specifier ID\n" << $$->getName() << endl;
        }
    }
    | type_specifier    {
        $$ = new SymbolInfo($1->getName(), "parameter_list");
        logFile << "Line " << line_count << ": parameter_list: type_specifier\n" << $$->getName() << endl;
    }
    ;

compound_statement: LCURL statements RCURL  {
        symbolTable.exitScope();
        $$ = new SymbolInfo("{\n"+$2->getName()+"\n}", "compound_statement");
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
        for(string s : splitted){
            SymbolInfo* variable;

            if(isVarArray(s)){
                string name = getArrayName(s);
                string len = getArrayLength(s);
                variable = new SymbolInfo(name, $1->getName());
                variable->setArrayLength(len);
            }else{
                variable = new SymbolInfo(s, $1->getName());
            }

            if(!symbolTable.insert(variable)){
                error_count++;
                errorFile << "Error at line " << line_count << ": Multiple declaration of " << s << endl;
                logFile << "Line " << line_count << ": var_declaration : type_specifier declaration_list SEMICOLON\n";
                logFile << "Error at line " << line_count << ": Multiple declaration of " << s << endl;
                logFile << $2->getName() << endl;
            }
        }

        logFile << "Line " << line_count << ": var_declaration : type_specifier declaration_list SEMICOLON\n" << $2->getName() << endl;
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
        logFile << "Line " << line_count << ": declaration_list : ID LTHIRD CONST_INT RTHIRD\n" << $$->getName() << endl;
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
    | IF LPAREN expression RPAREN statement    %prec LOWER_THAN_ELSE   {
        $$ = new SymbolInfo("if("+$3->getName()+") "+$5->getName(), "statement");
        logFile << "Line " << line_count << ": statement : IF LPAREN expression RPAREN expression\n" << $$->getName() << endl;
    }
    | IF LPAREN expression RPAREN statement ELSE statement {
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
        $$ = new SymbolInfo("return "+$2->getName() + ";", "statement");
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
        string type = $1->getType();
        SymbolInfo* var = symbolTable.lookup($1->getName());

        if(var == NULL){
            error_count++;
            type = "error";
            errorFile << "Error at line " << line_count << ": Undeclared variable " << $1->getName() << endl;
            logFile << "Line " << line_count << ": variable : ID\n";
            logFile << "Error at line " << line_count << ": Undeclared variable " << $1->getName() << endl;
            logFile << $1->getName() << endl;
        }else if(var->getArrayLength() != ""){
            if($1->getArrayLength() == ""){
                error_count++;
                type = "error";
                errorFile << "Error at line " << line_count << ": Type mismatch, " << $1->getName() << " is an array" << endl;
                logFile << "Line " << line_count << ": variable : ID\n"; 
                logFile << "Error at line " << line_count << ": Type mismatch, " << $1->getName() << " is an array" << endl;
                logFile << $1->getName() << endl;
            }
        }else{
            type = var->getType();
            logFile << "Line " << line_count << ": variable : ID\n" << $1->getName() << endl;
        }

        $$ = new SymbolInfo($1->getName(), type);
    }
    | ID LTHIRD expression RTHIRD   { 
        $$ = new SymbolInfo($1->getName()+"["+$3->getName()+"]", $1->getType());

        if(symbolTable.lookup($1->getName()) == NULL){
            error_count++;
            errorFile << "Error at line " << line_count << ": Undeclared variable " << $1->getName() << endl;
            logFile << "Line " << line_count << ": variable : ID LTHIRD expression RTHIRD\n"; 
            logFile << "Error at line " << line_count << ": Undeclared variable " << $1->getName() << endl;
            logFile << $$->getName() << endl;
            $$->setType("error");
        }else{
            if($3->getType() != "CONST_INT"){
                error_count++;
                errorFile << "Error at line " << line_count << ": Expression inside third brackets not an integer" << endl;
                logFile << "Line " << line_count << ": variable : ID LTHIRD expression RTHIRD\n"; 
                logFile << "Error at line " << line_count << ": Expression inside third brackets not an integer" << endl;
                logFile << $$->getName() << endl;
                $$->setType("error");
            }else{
                logFile << "Line " << line_count << ": variable : ID LTHIRD expression RTHIRD\n" << $$->getName() << endl;
            }
        } 
    }
    ;

expression: logic_expression    {
        $$ = $1;
        logFile << "Line " << line_count << ": expression : logic_expression\n" << $$->getName() << endl;
    }
    | variable ASSIGNOP logic_expression    {
        string type = $1->getType();
        SymbolInfo* var = symbolTable.lookup($1->getName());
        
        $$ = new SymbolInfo($1->getName()+"="+$3->getName(), type);

        if(var == NULL){
            logFile << "Line " << line_count << ": expression : variable ASSIGNOP logic_expression\n" << $$->getName() << endl;
        }else{
            string varType = var->getType();
            string valType = $3->getType();

            if((varType=="int" && valType=="CONST_INT") || (varType=="float" && valType=="CONST_FLOAT")){
                logFile << "Line " << line_count << ": expression : variable ASSIGNOP logic_expression\n" << $$->getName() << endl;
            }else if(valType == "error"){
                $$->setType("error");
                logFile << "Line " << line_count << ": expression : variable ASSIGNOP logic_expression\n" << $$->getName() << endl;
            }else{
                error_count++;
                type = "error";
                errorFile << "Error at line " << line_count << ": Type mismatch" << endl;
                logFile << "Line " << line_count << ": expression : variable ASSIGNOP logic_expression\n";
                logFile << "Error at line " << line_count << ": Type mismatch" << endl;
                logFile << $$->getName() << endl;
            }
        }
    }
    ;

logic_expression: rel_expression    {
        $$ = $1;
        logFile << "Line " << line_count << ": logic_expression : rel_expression\n" << $$->getName() << endl;
    }
    | rel_expression LOGICOP rel_expression {
        $$ = new SymbolInfo($1->getName()+yylval.si->getName()+$3->getName(), "logic_expression");
        logFile << "Line " << line_count << ": logic_expression : rel_expression LOGICOP rel_expression\n" << $$->getName() << endl;
    }
    ;

rel_expression: simple_expression   {
        $$ = $1;
        logFile << "Line " << line_count << ": rel_expression : simple_expression\n" << $$->getName() << endl;
    }
    | simple_expression RELOP simple_expression {
        $$ = new SymbolInfo($1->getName()+yylval.si->getName()+$3->getName(), "rel_expression");
        logFile << "Line " << line_count << ": rel_expression : simple_expression RELOP simple_expression\n" << $$->getName() << endl;
    }
    ;

simple_expression: term {
        $$ = $1;
        logFile << "Line " << line_count << ": simple_expression : term\n" << $$->getName() << endl;
    }
    | simple_expression ADDOP term  {
        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), "simple_expression");
        logFile << "Line " << line_count << ": simple_expression : simple_expression ADDOP term\n" << $$->getName() << endl;
    }
    ;

term: unary_expression  {
        $$ = $1;
        logFile << "Line " << line_count << ": term : unary_expression\n" << $$->getName() << endl;
    }
    | term MULOP unary_expression   {
        string type = $3->getType();

        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), type);

        if(($2->getName() == "%") && (($1->getType() != "CONST_INT") || ($3->getType() != "CONST_INT"))){
            error_count++;
            $$->setType("error");
            errorFile << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl;
            logFile << "Line " << line_count << ": term : term MULOP unary_expression\n";
            logFile << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl;
            logFile << $$->getName() << endl;
        }else{
            logFile << "Line " << line_count << ": term : term MULOP unary_expression\n" << $$->getName() << endl;
        }
    }
    ;

unary_expression: ADDOP unary_expression    {
        $$ = new SymbolInfo(yylval.si->getName()+$2->getName(), $2->getType());
        logFile << "Line " << line_count << ": unary_expression : ADDOP unary_expression\n" << $$->getName() << endl;
    }
    | NOT unary_expression  {
        $$ = new SymbolInfo("!"+$2->getName(), $2->getType());
        logFile << "Line " << line_count << ": unary_expression : NOT unary_expression\n" << $$->getName() << endl;
    }
    | factor    {
        $$ = $1;
        logFile << "Line " << line_count << ": unary_expression : factor\n" << $$->getName() << endl;
    }
    ;

factor: variable    {
        $$ = $1;
        logFile << "Line " << line_count << ": factor : variable\n" << $$->getName() << endl;
    }
    | ID LPAREN argument_list RPAREN    { 
        $$ = new SymbolInfo($1->getName()+"("+$3->getName()+")", "factor");
        logFile << "Line " << line_count << ": factor : ID LPAREN argument_list RPAREN\n" << $$->getName() << endl;
    }
    | LPAREN expression RPAREN  {
        $$ = new SymbolInfo("("+$2->getName()+")", $2->getType());
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
        $$ = new SymbolInfo($1->getName()+"++", $1->getType());
        logFile << "Line " << line_count << ": factor : variable INCOP\n" << $$->getName() << endl;
    }
    | variable DECOP    {
        $$ = new SymbolInfo($1->getName()+"--", $1->getType());
        logFile << "Line " << line_count << ": factor : variable DECOP\n" << $$->getName() << endl;
    }
    ;

argument_list: arguments    {
        $$ = $1;
        logFile << "Line " << line_count << ": argument_list : arguments\n" << $$->getName() << endl;
    }
    |   {
        $$ = new SymbolInfo("argument_list", "empty");
    }
    ;

arguments: arguments COMMA logic_expression {
        $$ = new SymbolInfo($1->getName()+","+$3->getName(), $1->getType()+","+$3->getType());
        logFile << "Line " << line_count << ": arguments : arguments COMMA logic_expression\n" << $$->getName() << endl;
    }
    | logic_expression  {
        $$ = $1;
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
    errorFile.open("1805021_error.txt", ios::out);

    yyin = fin;
    yyparse();
    fclose(yyin);

    logFile.close();
    errorFile.close();

    exit(0);
}
