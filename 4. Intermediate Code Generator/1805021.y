%{
 #include <bits/stdc++.h>
 #include "1805021_SymbolTable.h"
 
 extern FILE *yyin;

 #define BUCKETS 7

 int line_count = 1;
 int error_count = 0;
 int tempCount = 0;
 int labelCount = 0;
 int sp = 0;
 int labelCount=0;
 int tempCount=0;

 fstream logFile;
 fstream errorFile;
 fstream asmFile;
 fstream optimizedFile;
 SymbolTable symbolTable(BUCKETS);
 vector<string> dataVars;
 vector<string> temp_SP_vector;

 void yyerror(char *s){
    error_count++;
    errorFile << "Error at line " << line_count << ": "<< s << endl;
 }

 int yylex(void);

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

 string newTemp() {
	string temp = "temp_" + to_string(tempCount++);
	incrementSP();
	return temp;
 }

 string newLabel() {
    return "label_" + to_string(labelCount++);
 }

 void incrementSP(int width = -1){
    if(width == -1) sp += 2;
    else sp += width*2;
 }

 string defineWord(string word){
  return word + " dw ?";
 }

 string getJumpText(string relop){
    if(relop=="<") return "jl";
    if(relop=="<=") return "jle";
    if(relop==">") return "jg";
    if(relop==">=") return "jge";
    if(relop=="==") return "je";
    if(relop=="!=") return "jne";
 }

 string stk_address(string stk_offset){
    return "[bp-"+stk_offset+"]";
 }

 string stk_address_param(string stk_offset){
    return "[bp+"+stk_offset+"]";
 }

 string stk_address_typecast(string stk_offset){
    return "WORD PTR [bp-"+stk_offset+"]";
 }

 string cur_function_label(string name){
    return "L_"+name;
 }

 string process_global_variable(string str){
    vector<string> ret;
    char delim = '[';

    size_t start;
    size_t end = 0;

    while ((start = str.find_first_not_of(delim, end)) != string::npos)
    {
        end = str.find(delim, start);
        ret.push_back(str.substr(start, end - start));
    }

    int sz = ret.size();

    if(sz == 1) return ret[0];
    else return ret[0]+"[BX]";
 }

 vector<string> tokenize(string str,char delim){
    vector<string> ret;

    size_t start;
    size_t end = 0;

    while ((start = str.find_first_not_of(delim, end)) != string::npos)
    {
        end = str.find(delim, start);
        ret.push_back(str.substr(start, end - start));
    }

    return ret;
 }

 bool isATempVariable(string s){
    for(string x:temp_SP_vector)
        if(x == s) return true;

    return false;
 }

 void debug(){
    logFile << "-------------------------\n";
    logFile << "DEBUG\n";
    logFile << "-------------------------\n";
    symbolTable.printAllScopeTables(logFile);
 }

%}

%union{
    SymbolInfo* si;
}

%token<si> ADDOP ID MULOP CONST_INT CONST_FLOAT CONST_CHAR RELOP LOGICOP
%token IF ELSE WHILE FOR NUMBER INT FLOAT VOID PRINTLN RETURN
%token NOT ASSIGNOP LPAREN RPAREN COMMA SEMICOLON  INCOP DECOP LCURL RCURL LTHIRD RTHIRD

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
        string name = $2->getName();
        string type = "func_declaration";
        SymbolInfo* var = symbolTable.lookup(name);

        if(var == NULL){
            vector<string> paramList = splitString($4->getName(), ',');
            var = new SymbolInfo(name, $2->getType());
            var->setDataType("function");
            var->setFunctionReturnType($1->getName());
            var->setParams(paramList);
            symbolTable.insert(var);
            logFile << "Line " << line_count << ": func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n";
        }else{
            error_count++;
            type = "error";
            errorFile << "Error at line " << line_count << ": Multiple declaration of " << name << endl;
            logFile << "Line " << line_count << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n";
            logFile << "Error at line " << line_count << ": Multiple declaration of " << name << endl;
        }
        
        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+"("+$4->getName()+");", type);
        logFile << $$->getName() << endl;
    }
    | type_specifier ID LPAREN RPAREN SEMICOLON {
        string type = "func_declaration";
        string name = $2->getName();
        SymbolInfo* var = symbolTable.lookup(name);

        if(var == NULL){
            vector<string> paramList;
            var = new SymbolInfo(name, $2->getType());
            var->setDataType("function");
            var->setFunctionReturnType($1->getName());
            var->setParams(paramList);
            symbolTable.insert(var);
            logFile << "Line " << line_count << ": func_declaration: type_specifier ID LPAREN RPAREN SEMICOLON\n";
        }else{
            error_count++;
            type = "error";
            errorFile << "Error at line " << line_count << ": Multiple declaration of " << name << endl;
            logFile << "Line " << line_count << ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n";
            logFile << "Error at line " << line_count << ": Multiple declaration of " << name << endl;
        }

        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+"();", type);
        logFile << $$->getName() << endl;
    }
    ;

func_definition: type_specifier ID LPAREN parameter_list RPAREN { 
        string name = $2->getName();
        SymbolInfo* var = symbolTable.lookup(name);

        if(var == NULL){
            vector<string> paramList = splitString($4->getName(), ',');
            var = new SymbolInfo(name, $2->getType());
            var->setDataType("function");
            var->setParams(paramList);
            var->setFunctionDefined(true);
            var->setFunctionReturnType($1->getName());
            symbolTable.insert(var);
            symbolTable.enterScope();
            bool discrepancy = false;
            for(int i = 0; i < paramList.size(); i++){
                vector<string> variable = splitString(paramList[i], ' ');
                string varType = "";
                string varName = "";
                if(variable.size() == 2){
                    varType = variable[0];
                    varName = variable[1];
                    SymbolInfo* temp;
                    temp = new SymbolInfo(varName, "ID");
                    temp->setDataType(varType);

                    if(!symbolTable.insert(temp)){
                        error_count++;
                        errorFile << "Error at line " << line_count << ": Multiple declaration of " << varName << " in parameter" << endl;
                        logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN parameter_list RPAREN\n";
                        logFile << "Error at line " << line_count << ": Multiple declaration of " << varName << " in parameter" << endl;
                    }
                }else{
                    if(!discrepancy){
                        error_count++;
                        discrepancy = true;
                        errorFile << "Error at line " << line_count << ": " << (i+1) << "th parameter's name not given in function definition of " <<  name << endl;
                        logFile << "Error at line " << line_count << ": " << (i+1) << "th parameter's name not given in function definition of " <<  name << endl;
                    }
                }
            }
            //logFile << "Line " << line_count << ": func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n" << $$->getName() << endl;
        }else{
            if(var->getDataType() == "function"){
                vector<string> declaredParams = var->getParams();
                bool isDefined = var->getFunctionDefined();
                int declaredParamLen = declaredParams.size();
                vector<string> definedParams = splitString($4->getName(), ',');
                int definedParamLen = definedParams.size();

                if(isDefined){
                    error_count++;
                    errorFile << "Error at line " << line_count << ": Multiple declaration of function\n";
                    logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN parameter_list RPAREN\n";
                    logFile << "Error at line " << line_count << ": Multiple declaration of function " << name << endl;
                }else{
                    if(declaredParamLen != definedParamLen){
                        error_count++;
                        errorFile << "Error at line " << line_count << ": Total number of arguments mismatch with declaration in function " << name << endl;
                        logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN parameter_list RPAREN\n";
                        logFile << "Error at line " << line_count << ": Total number of arguments mismatch with declaration in function " << name << endl;
                    }
                    if($1->getName() != var->getFunctionReturnType()){
                        error_count++;
                        errorFile << "Error at line " << line_count << ": Return type mismatch with function declaration in function " << name << endl;
                        logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN parameter_list RPAREN\n";
                        logFile << "Error at line " << line_count << ": Return type mismatch with function declaration in function " << name << endl;
                    }

                    symbolTable.remove(name);
                    SymbolInfo* f = new SymbolInfo(name, $2->getType());
                    f->setDataType("function");
                    f->setParams(declaredParams);
                    f->setFunctionDefined(true);
                    f->setFunctionReturnType($1->getName());
                    symbolTable.insert(f);
                    symbolTable.enterScope();
                    for(int i = 0; i < definedParamLen; i++){
                        string p = definedParams[i];
                        string q = declaredParams[i];
                        if(splitString(p, ' ')[0] != splitString(q, ' ')[0]){
                            error_count++;
                            errorFile << "Error at line " << line_count << ": " << (i+1) << "th parameter's type mismatch in function definition of " << name << endl;
                            logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN parameter_list RPAREN\n";
                            logFile << "Error at line " << line_count << ": " << (i+1) << "th parameter's type mismatch in function definition of\n" << name << endl;
                        }
                        vector<string> definedVariable = splitString(p, ' ');
                        string varType = definedVariable[0];
                        string varName = definedVariable[1];
                        SymbolInfo* temp;
                        temp = new SymbolInfo(varName, "ID");
                        temp->setDataType(varType);

                        if(!symbolTable.insert(temp)){
                            error_count++;
                            errorFile << "Error at line " << line_count << ": Multiple declaration of " << varName << endl;
                            logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN parameter_list RPAREN\n";
                            logFile << "Error at line " << line_count << ": Multiple declaration of " << varName << endl;
                        }
                    }
                }
            }else{
                symbolTable.enterScope();
                vector<string> definedParams = splitString($4->getName(), ',');

                for(int i = 0; i < definedParams.size(); i++){
                    vector<string> definedVariable = splitString(definedParams[i], ' ');
                    SymbolInfo* temp = new SymbolInfo(definedVariable[1], "error");
                    symbolTable.insert(temp);
                }

                error_count++;
                errorFile << "Error at line " << line_count << ": Multiple declaration of " << name << endl;
                logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN parameter_list RPAREN\n";
                logFile << "Error at line " << line_count << ": Multiple  declaration of " << name << endl;
            }
        }

        
    }
    compound_statement  {
        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+"("+$4->getName()+")"+$7->getName(), "func_definition");
        logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN parameter_list RPAREN compound_statement\n" << $$->getName() << endl;
    }
    | type_specifier ID LPAREN RPAREN   { 
        string type = "func_definition";
        string name = $2->getName();
        SymbolInfo* var = symbolTable.lookup(name);

        if(var == NULL){
            vector<string> paramList;
            var = new SymbolInfo(name, $2->getType());
            var->setDataType("function");
            var->setParams(paramList);
            var->setFunctionDefined(true);
            var->setFunctionReturnType($1->getName());
            symbolTable.insert(var);
            symbolTable.enterScope();
        }else{
            if(var->getDataType() == "function"){
                vector<string> declaredParams = var->getParams();
                bool isDefined = var->getFunctionDefined();
                int declaredParamLen = declaredParams.size();
                vector<string> definedParams;
                int definedParamLen = 0;

                if(isDefined){
                    error_count++;
                    errorFile << "Error at line " << line_count << ": Multiple declaration of function\n";
                    logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN RPAREN\n";
                    logFile << "Error at line " << line_count << ": Multiple declaration of function " << name << endl;
                }else{
                    if(declaredParamLen != definedParamLen){
                        error_count++;
                        errorFile << "Error at line " << line_count << ": Total number of arguments mismatch with declaration in function " << name << endl;
                        logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN RPAREN\n";
                        logFile << "Error at line " << line_count << ": Total number of arguments mismatch with declaration in function " << name << endl;
                    }
                    if($1->getName() != var->getFunctionReturnType()){
                        error_count++;
                        errorFile << "Error at " << line_count << ": Return type mismatch with function declaration in function " << name << endl;
                        logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN RPAREN\n";
                        logFile << "Error at line " << line_count << ": Return type mismatch with function declaration in function " << name << endl;
                    }
                    symbolTable.remove(name);
                    SymbolInfo* f = new SymbolInfo(name, $2->getType());
                    f->setDataType("function");
                    f->setParams(declaredParams);
                    f->setFunctionDefined(true);
                    f->setFunctionReturnType($1->getName());
                    symbolTable.insert(f);
                    symbolTable.enterScope();
                }
            }else{
                symbolTable.enterScope();
                error_count++;
                errorFile << "Error at line " << line_count << ": Variable not a function\n";
                logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN RPAREN\n";
                logFile << "Error at line " << line_count << ": Variable not a function " << name << endl;
            }
        }        
    }
    compound_statement  {
        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+"()"+$6->getName(), "func_definition");
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
        $$ = $1;
        logFile << "Line " << line_count << ": parameter_list: type_specifier\n" << $$->getName() << endl;
    }
    | type_specifier error  {
        yyclearin;
        yyerrok;
        $$ = new SymbolInfo($1->getName(), "error");
        logFile << "Line " << line_count << ": parameter_list: type_specifier\n" << $$->getName() << endl;
        logFile << "Error at line " << line_count << ": syntax error\n" << $$->getName() << endl;
    } 
    ;

compound_statement: LCURL statements RCURL  {
        $$ = new SymbolInfo("{\n"+$2->getName()+"\n}", $2->getType());
        logFile << "Line " << line_count << ": compound_statement: LCURL statements RCURL\n" << $$->getName() << endl;
        symbolTable.printAllScopeTables(logFile);
        symbolTable.exitScope();
    }
    | LCURL RCURL   {
        symbolTable.printAllScopeTables(logFile);
        symbolTable.exitScope();
        $$ = new SymbolInfo("{}", "compound_statement");
        logFile << "Line " << line_count << ": compound_statement: LCURL RCURL\n" << $$->getName() << endl;
    }
    ;

var_declaration: type_specifier declaration_list SEMICOLON  {
        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+";", "var_declaration");
        vector<string> splitted = splitString($2->getName(), ',');
        
        if($1->getName() == "void"){
            error_count++;
            errorFile << "Error at line " << line_count << ": Variable type cannot be void\n";
            logFile << "Line " << line_count << ": var_declaration : type_specifier declaration_list SEMICOLON\n";
        }else{
            int offset = 0;
            int width = 4;
            for(string s : splitted){
                SymbolInfo* variable;

                if(isVarArray(s)){
                    string name = getArrayName(s);
                    string len = getArrayLength(s);
                    variable = new SymbolInfo(name, $2->getType());
                    variable->setArrayLength(len);
                    variable->setDataType($1->getName());

                    if(symbolTable.getCurrentTableID() == "1"){

                    }else{

                    }
                }else{
                    variable = new SymbolInfo(s, $2->getType());
                    variable->setDataType($1->getName());
                    variable->setOffset(offset);
                    offset += width;
                }

                if(!symbolTable.insert(variable)){
                    if(isVarArray(s)) s = getArrayName(s);
                    error_count++;
                    errorFile << "Error at line " << line_count << ": Multiple declaration of " << s << endl;
                    logFile << "Line " << line_count << ": var_declaration : type_specifier declaration_list SEMICOLON\n";
                    logFile << "Error at line " << line_count << ": Multiple declaration of " << s << endl;
                    logFile << $2->getName() << endl;
                }
            }
        }

        logFile << "Line " << line_count << ": var_declaration : type_specifier declaration_list SEMICOLON\n" << $$->getName() << endl;
    }
    | error SEMICOLON   {
        yyclearin;
        yyerrok;
        $$ = new SymbolInfo("", "error");
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
        $$ = new SymbolInfo($1->getName()+","+$3->getName(), $3->getType());
        logFile << "Line " << line_count << ": declaration_list : declaration_list COMMA ID\n" << $$->getName() << endl;
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
        $$ = new SymbolInfo($1->getName()+","+$3->getName()+"["+$5->getName()+"]", "declaration_list");
        logFile << "Line " << line_count << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n" << $$->getName() << endl;
    }
    | ID    {
        $$ = new SymbolInfo($1->getName(), $1->getType());
        logFile << "Line " << line_count << ": declaration_list : ID\n" << $1->getName() << endl;
    }
    | ID LTHIRD CONST_INT RTHIRD    {
        $$ = new SymbolInfo($1->getName()+"["+$3->getName()+"]", "ID");
        logFile << "Line " << line_count << ": declaration_list : ID LTHIRD CONST_INT RTHIRD\n" << $$->getName() << endl;
    }
    |declaration_list error {
        yyclearin;
        $$ = new SymbolInfo($1->getName(), "error");
        logFile << $1->getName() << endl;
    }
    ;

statements: statement   {
        $$ = $1;
        logFile << "Line " << line_count << ": statements : statement\n" << $$->getName() << endl;
    }
    | statements statement  {
        $$ = new SymbolInfo($1->getName()+"\n"+$2->getName(), "statements");
        $$->setAsmCode($1->getAsmCode() + $2->getAsmCode);
        logFile << "Line " << line_count << ": statements : statements statement\n" << $$->getName() << endl;
    }
    ;

statement: var_declaration  {
        $$ = new SymbolInfo($1->getName(), "statement");
        logFile << "Line " << line_count << ": statement : var_declaration\n" << $$->getName() << endl;

        $$->asmText = $1->asmText;
        $$->offset = $1->offset;
        $$->tempVar = $1->tempVar;
        $$->asmCode = $1->asmCode;
    }
    | expression_statement  {
        $$ = new SymbolInfo($1->getName(), "statement");
        logFile << "Line " << line_count << ": statement : expression_statement\n" << $$->getName() << endl;

        $$->asmText = $1->asmText;
        $$->offset = $1->offset;
        $$->tempVar = $1->tempVar;
        $$->asmCode = "; " + $$->asmText + "\n" + $1->asmCode;
    }
    | {
        symbolTable.enterScope();
    }compound_statement    {
        $$ = new SymbolInfo($2->getName(), "statement");
        logFile << "Line " << line_count << ": statement : compound_statement\n" << $$->getName() << endl;

        $$->asmText = $2->asmText;
        $$->offset = $2->offset;
        $$->tempVar = $2->tempVar;
        $$->asmCode = $2->asmCode;
    }
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement  {
        $$ = new SymbolInfo("for("+$3->getName()+" "+$4->getName()+" "+$5->getName()+") "+$7->getName(), "statement");
        logFile << "Line " << line_count << ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n" << $$->getName() << endl;

        $$->asmText = "for(" + $3->asmText + " " + $4->asmText + " " + $5->asmText + ") " + $7->asmText;
        string t1 = newLabel();
        string t2 = newLabel();

        string to_print = $$->asmText;
        to_print.erase(remove(to_print.begin(), to_print.end(), '\n'), to_print.end());

        $$->asmCode = "; " + to_print + "\n";

        $$->asmCode += $3->asmCode + "\n";

        $$->asmCode += t1 + ":\n"; // loop starting label

        $$->asmCode += "; " + $4->asmText + "\n";
        $$->asmCode += $4->asmCode + "\n"; // eval expression

        $$->asmCode += "; check for loop condition\n";
        $$->asmCode += "CMP " + stk_address($4->offset) + ", 0\n"; // check if need to exit
        $$->asmCode += "JE " + t2 + "\n"; // check if need to exit

        $$->asmCode += $7->asmCode + "\n";  // exec statement

        $$->asmCode += "; " + $5->asmText + "\n";  // exec statement
        $$->asmCode += $5->asmCode + "\n";  // exec statement

        $$->asmCode += "JMP " + t1 + "\n"; // loop
        $$->asmCode += t2 + ":\n"; // loop ending label
    }
    | IF LPAREN expression RPAREN statement    %prec LOWER_THAN_ELSE   {
        $$ = new SymbolInfo("if("+$3->getName()+") "+$5->getName(), "statement");
        logFile << "Line " << line_count << ": statement : IF LPAREN expression RPAREN expression\n" << $$->getName() << endl;

        $$->asmText = "if(" + $3->asmText + ") " + $5->asmText;
        string to_print = $$->asmText;
        to_print.erase(remove(to_print.begin(), to_print.end(), '\n'), to_print.end());

        $$->asmCode = "; " + to_print + "\n";

        $$->asmCode += $3->asmCode + "\n";
        
        string t1 = newLabel();
        $$->asmCode += "CMP " + stk_address($3->offset) + ", 0\n";
        $$->asmCode += "JE " + t1 + "\n";
        $$->asmCode += $5->asmCode + "\n";
        $$->asmCode += t1 + ":\n";
    }
    | IF LPAREN expression RPAREN statement ELSE statement {
        $$ = new SymbolInfo("if("+$3->getName()+") "+$5->getName()+" else "+$7->getName(), "statement");
        logFile << "Line " << line_count << ": statement : IF LPAREN expression RPAREN expression ELSE statement\n" << $$->getName() << endl;

        $$->asmText = "if(" + $3->asmText + ") " + $5->asmText + " else " + $7->asmText;
        string to_print = $$->asmText;
        to_print.erase(remove(to_print.begin(), to_print.end(), '\n'), to_print.end());

        $$->asmCode = "; " + to_print + "\n";

        $$->asmCode += $3->asmCode + "\n";
        
        string t1 = newLabel();
        string t2 = newLabel();

        $$->asmCode += "CMP " + stk_address($3->offset) + ", 0\n";
        $$->asmCode += "JE " + t1 + "\n";

        $$->asmCode += $5->asmCode + "\n";
        $$->asmCode += "JMP " + t2 + "\n";
        $$->asmCode += t1 + ":\n";

        $$->asmCode += $7->asmCode + "\n";
        $$->asmCode += t2 + ":\n";
    }
    | WHILE LPAREN expression RPAREN statement  {
        $$ = new SymbolInfo("while("+$3->getName()+") "+$5->getName(), "statement");
        logFile << "Line " << line_count << ": statement : WHILE LPAREN expression RPAREN statement\n" << $$->getName() << endl;

        $$->asmText = "while(" + $3->asmText() + ") " + $5->asmText();
        string t1 = newLabel();
        string t2 = newLabel();

        string to_print = $$->asmText;
        to_print.erase(remove(to_print.begin(), to_print.end(), '\n'), to_print.end());

        $$->asmCode = "; " + to_print + "\n";

        $$->asmCode += t1 + ":\n"; // loop starting label

        $$->asmCode += "; " + $3->asmText + "\n";
        $$->asmCode += $3->asmCode + "\n"; // eval expression

        $$->asmCode += "; check while loop condition\n";
        $$->asmCode += "CMP " + stk_address($3->offset) + ", 0\n"; // check if need to exit
        $$->asmCode += "JE " + t2 + "\n"; // check if need to exit

        $$->asmCode += $5->asmCode + "\n";  // exec statement

        $$->asmCode += "JMP " + t1 + "\n"; // loop
        $$->asmCode += t2 + ":\n"; // loop ending label
    }
    | PRINTLN LPAREN ID RPAREN SEMICOLON    {
        $$ = new SymbolInfo("printf("+$3->getName()+")", "statement");
        $$->asmText = "printf(" + $3->getName() + ");";
        $$->asmCode = "\n; " + $$->asmText + "\n";

        SymbolInfo* var  = symbolTable.lookup($3->getName());
        if(var == NULL){
            error_count++;
            errorFile << "Error at line " << line_count << ": Undeclared variable " << $3->getName() << endl;
            logFile << "Line " << line_count << ": statement: PRINTLN LPAREN ID RPAREN SEMICOLON\n";
            logFile << "Error at line " << line_count << ": Undeclared variable " << $3->getName() << endl;
        }else{
            logFile << "Line " << line_count << ": statement: PRINTLN LPAREN ID RPAREN SEMICOLON\n";
        }

        logFile << $$->getName() << endl;
            
        if(var != NULL && var->offset != "") $$->asmCode += "MOV AX, " + stk_address(var->offset) + "\n";
        else $$->asmCode += "MOV AX, " + $3->getName() + "\n";
        
        $$->asmCode += "MOV FOR_PRINT, AX\n";
        $$->asmCode += "CALL OUTPUT";
    }
    | RETURN expression SEMICOLON   {
        $$ = new SymbolInfo("return "+$2->getName() + ";", $2->getType());
        logFile << "Line " << line_count << ": statement : RETURN expression SEMICOLON\n" << $$->getName() << endl;

        $$->asmText = "return " + $1->asmText + ";";
        $$->asmCode = "; " + $$->asmText + "\n";
        $$->asmCode += $2->asmCode + "\n";

        if($2->offset != "") $$->asmCode += "MOV AX, " + stk_address($2->offset) + "\n";
        else{
            $$->asmCode += "MOV AX, " + process_global_variable($2->asmText) + "\n";
        } 

        $$->asmCode += "JMP " + cur_function_label(cur_function_name)+"\n";
    }
    ;

expression_statement: SEMICOLON {
        $$ = new SymbolInfo(";", "expression_statement");
        $$->asmText = ";";
        logFile << "Line " << line_count << ": expression_statement : SEMICOLON\n;\n";
    }
    | expression SEMICOLON  {
        $$ = new SymbolInfo($1->getName()+";", "expression_statement");
        logFile << "Line " << line_count << ": expression_statement : expression SEMICOLON\n" << $$->getName() << endl;

        $$->asmText = $1->asmText + ";";
        $$->asmCode = $1->asmCode;
        $$->offset = $1->offset;
        $$->tempVar = $1->tempVar;
    }
    | expression error  {
        yyclearin;
        $$ = new SymbolInfo("", "error");
    }
    ;

variable: ID    {
        string type = $1->getType();
        SymbolInfo* var = symbolTable.lookup($1->getName());

        $$->asmText = $1->getName();

        if(var == NULL){
            error_count++;
            type = "error";
            errorFile << "Error at line " << line_count << ": Undeclared variable " << $1->getName() << endl;
            logFile << "Line " << line_count << ": variable : ID\n";
            logFile << "Error at line " << line_count << ": Undeclared variable " << $1->getName() << endl;
            logFile << $1->getName() << endl;
        }else if(var->getType() == "error"){
            type="error";
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
            type = var->getDataType();
            logFile << "Line " << line_count << ": variable : ID\n" << $1->getName() << endl;
        }

        $$ = new SymbolInfo($1->getName(), type);
        $$->tempVar = $1->getName();

        if(var != NULL) $$->offset = var->offset;
    }
    | ID LTHIRD expression RTHIRD   { 
        string type = $1->getType();
        SymbolInfo* var = symbolTable.lookup($1->getName());

        $$->asmText = $1->getName() + "[" + $3->asmText + "]";

        if(var == NULL){
            error_count++;
            type = "error";
            errorFile << "Error at line " << line_count << ": Undeclared variable " << $1->getName() << endl;
            logFile << "Line " << line_count << ": variable : ID LTHIRD expression RTHIRD\n"; 
            logFile << "Error at line " << line_count << ": Undeclared variable " << $1->getName() << endl;
        }else{
            if(var->getArrayLength() == ""){
                error_count++;
                type = "error";
                errorFile << "Error at line " << line_count << ": " << $1->getName() << " not an array\n";
                logFile << "Line " << line_count << ": variable : ID LTHIRD expression RTHIRD\n"; 
                logFile << "Error at line " << line_count << ": " << $1->getName() << " not an array\n";
            }
            if($3->getType() != "CONST_INT"){
                error_count++;
                type = "error";
                errorFile << "Error at line " << line_count << ": Expression inside third brackets not an integer" << endl;
                logFile << "Line " << line_count << ": variable : ID LTHIRD expression RTHIRD\n"; 
                logFile << "Error at line " << line_count << ": Expression inside third brackets not an integer" << endl;
            }

            if(type != "error"){
                type = var->getDataType();
                logFile << "Line " << line_count << ": variable : ID LTHIRD expression RTHIRD\n";
            }
        }

        $$ = new SymbolInfo($1->getName()+"["+$3->getName()+"]", type);
        logFile << $$->getName() << endl;

        if(var != NULL){
            $$->asmCode = $3->asmCode = "\n";

            if(var->stk_offset!=""){
                $$->asmCode += "MOV SI, " + stk_address($3->offset) + "\n";
                $$->asmCode += "ADD SI, SI";
                $$->offset = var->offset + " + SI";
            }else{
                $$->asmCode += "MOV BX, " + stk_address($3->offset) + "\n";
                $$->asmCode += "ADD BX, BX";
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

        string varType = $1->getDataType();
        string valType = $3->getDataType();

        if(($1->getType()=="error") || ($3->getType()=="error")){
            type = "error";
            logFile << "Line " << line_count << ": expression : variable ASSIGNOP logic_expression\n";
        }else if($3->getType() == "void_error"){
            error_count++;
            type = "error";
            errorFile << "Error at line " << line_count << ": Void function used in expression\n";
            logFile << "Line " << line_count << ": expression : variable ASSIGNOP logic_expression\n";
            logFile << "Error at line " << line_count << ": Void function used in expression\n";
        }else if(((varType=="int") && ((valType=="CONST_INT") || (valType=="int"))) || ((varType=="float") && ((valType=="CONST_FLOAT") || (valType=="float")))){
            logFile << "Line " << line_count << ": expression : variable ASSIGNOP logic_expression\n";
        }else if(((varType=="float") && ((valType=="CONST_INT")||(valType=="int")))){
            logFile << "Line " << line_count << ": expression : variable ASSIGNOP logic_expression\n";
        }else{
            error_count++;
            type = "error";
            errorFile << "Error at line " << line_count << ": Type mismatch\n";
            logFile << "Line " << line_count << ": expression : variable ASSIGNOP logic_expression\n";
            logFile << "Error at line " << line_count << ": Type mismatch\n";
        }

        $$ = new SymbolInfo($1->getName()+"="+$3->getName(), type);
        logFile << $$->getName() << endl;

        $$->asmCode = $3->asmCode + "\n";

        if($3->offset != "") $$->asmCode += "MOV CX,"+stk_address($3->offset)+"\n";
        else $$->code += "MOV CX,"+process_global_variable($3->text)+"\n";

        if($1->code != "") $$->asmCode += $1->code+"\n";

        if($1->offset != "") $$->asmCode += "MOV " + stk_address_typecast($1->offset) + ",CX";
        else $$->asmCode += "MOV " + process_global_variable($1->text) + ", CX";
    }
    ;

logic_expression: rel_expression    {
        $$ = $1;
        logFile << "Line " << line_count << ": logic_expression : rel_expression\n" << $$->getName() << endl;
    }
    | rel_expression LOGICOP rel_expression {
        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), "int");
        logFile << "Line " << line_count << ": logic_expression : rel_expression LOGICOP rel_expression\n" << $$->getName() << endl;
    }
    ;

rel_expression: simple_expression   {
        $$ = $1;
        logFile << "Line " << line_count << ": rel_expression : simple_expression\n" << $$->getName() << endl;
    }
    | simple_expression RELOP simple_expression {
        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), "int");
        logFile << "Line " << line_count << ": rel_expression : simple_expression RELOP simple_expression\n" << $$->getName() << endl;
    }
    ;

simple_expression: term {
        $$ = $1;
        logFile << "Line " << line_count << ": simple_expression : term\n" << $$->getName() << endl;
    }
    | simple_expression ADDOP term  {
        string type = "int";
        if(($1->getDataType()=="float" || $1->getDataType()=="CONST_FLOAT") || ($3->getDataType()=="float" || $3->getDataType()=="CONST_FLOAT")) type="float";
        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), type);
        logFile << "Line " << line_count << ": simple_expression : simple_expression ADDOP term\n" << $$->getName() << endl;
    }
    ;

term: unary_expression  {
        $$ = $1;
        logFile << "Line " << line_count << ": term : unary_expression\n" << $$->getName() << endl;
    }
    | term MULOP unary_expression   {
        string type = "int";
        if(($1->getDataType()=="float" || $1->getDataType()=="CONST_FLOAT") || ($3->getDataType()=="float" || $3->getDataType()=="CONST_FLOAT")) type="float";

        if(($2->getName() == "%") && (($1->getType() != "CONST_INT") || ($3->getType() != "CONST_INT"))){
            error_count++; 
            type = "error";
            errorFile << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl;
            logFile << "Line " << line_count << ": term : term MULOP unary_expression\n";
            logFile << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl;
        }
        if($3->getName() == "0"){
            error_count++;
            type = "error";
            errorFile << "Error at line " << line_count << ": Modulus by zero\n";
            logFile << "Line " << line_count << ": term : term MULOP unary_expression\n";
            logFile << "Error at line " << line_count << ": Modulus by zero\n";
        }
        if(($1->getType()=="void_error") || ($3->getType()=="void_error")){
            error_count++;
            type = "error";
            errorFile << "Error at line " << line_count << ": Void function used in expression\n";
            logFile << "Line " << line_count << ": factor : ID LPAREN argument_list RPAREN\n";
            logFile << "Error at line " << line_count << ":  Void function used in expression\n";
        }
        
        if(type != "error"){
            logFile << "Line " << line_count << ": term : term MULOP unary_expression\n";
        }

        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), type);
        logFile << $$->getName() << endl;
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
        string type = $1->getType();
        string functionName = $1->getName();
        SymbolInfo* function = symbolTable.lookup(functionName);

        $$->asmText = $1->getName() + "(" + $3->asmText + ")";

        if(function == NULL){
            error_count++;
            type = "error";
            errorFile << "Error at line " << line_count << ": Undeclared function " << functionName << endl;
            logFile << "Line " << line_count << ": factor : ID LPAREN argument_list RPAREN\n";
            logFile << "Error at line " << line_count << ": Undeclated function " << functionName << endl;
        }else if(function->getDataType() != "function"){
            error_count++;
            type = "error";
            errorFile << "Error at line " << line_count << ": Variable not a function " << functionName << endl;
            logFile << "Line " << line_count << ": factor : ID LPAREN argument_list RPAREN\n";
            logFile << "Error at line " << line_count << ": Variable not a function " << functionName << endl;
        }else{
            vector<string> params = function->getParams();
            vector<string> args = splitString($3->getType(), ',');

            if(params.size() != args.size()){
                error_count++;
                type = "error";
                errorFile << "Error at line " << line_count << ": Total number of arguments mismatch with declaration in function " << functionName << endl;
                logFile << "Line " << line_count << ": factor : ID LPAREN argument_list RPAREN\n";
                logFile << "Error at line " << line_count << ": Total number of arguments mismatch with declaration in function " << functionName << endl;
            }else if(function->getFunctionReturnType() == "void"){
                type = "void_error";
            }
            
            if(type!="error"){
                for(int i = 0; i < params.size(); i++){
                    bool discrepancy = false;
                    string paramType = splitString(params[i], ' ')[0];
                    string argType = splitString(args[i], ' ')[0];

                    if((paramType=="int" && (argType=="int" || argType=="CONST_INT")) || (paramType=="float" && (argType=="float" || argType=="CONST_FLOAT"))){

                    }else if(argType=="error"){

                    }else if((paramType != argType) && (type!="error")){
                        if(!discrepancy){
                            discrepancy = true;
                            error_count++;
                            if(type != "void_error") type = "error";
                            errorFile << "Error at line " << line_count << ": " << (i+1) << "th argument mismatch in function " << functionName << endl;
                            logFile << "Line " << line_count << ": factor : ID LPAREN argument_list RPAREN\n";
                            logFile << "Error at line " << line_count << ": " << (i+1) << "th argument mismatch in function " << functionName << endl;
                        }
                    }
                }
                if((type != "error") && (type != "void_error")) type = function->getFunctionReturnType();
            }
        }

        $$ = new SymbolInfo($1->getName()+"("+$3->getName()+")", type);
        if(type != "error") logFile << "Line " << line_count << ": factor : ID LPAREN argument_list RPAREN\n";
        logFile << $$->getName() << endl;

        if(type != "error"){
            $$->asmCode = $3->asmCode + "\n" + "CALL " + $1->getName() + "\n";
            $$->asmCode += "ADD SP, " + to_string(2*function->getParams.size());

            if(function->getFunctionReturnType() != "void"){
                $$->offset = to_string(sp);
                $$->code += "\nMOV " + stk_address_typecast($$->offset) + ", AX";
            }
        }
    }
    | LPAREN expression RPAREN  {
        $$ = new SymbolInfo("("+$2->getName()+")", $2->getType());
        logFile << "Line " << line_count << ": factor : LPAREN expression RPAREN\n" << $$->getName() << endl;

        $$->asmText = "(" + $2->asmText + ")";
        $$->asmCode = $2->asmCode;
        $$->offset = $2->offset;
        $$->tempVar = $2->tempVar;
    }
    | CONST_INT { 
        $$ = yylval.si;
        logFile << "Line " << line_count << ": factor : CONST_INT\n" << $$->getName() << endl;

        $$->asmText = $1->getName();
        string tempVar = newTemp();
        $$->tempVar = tempVar;
        $$->offset = to_string(sp);
        temp_SP_vector.push_back(to_string(sp));
        $$->asmCode = "MOV " + stk_address_typecast($$->offset) + ", " + $1->key;
     }
    | CONST_FLOAT   {
        $$ = yylval.si;
        logFile << "Line " << line_count << ": factor : CONST_FLOAT\n" << $$->getName() << endl;

        $$->asmText = $1->getName();
    }
    | variable INCOP    {
        $$ = new SymbolInfo($1->getName()+"++", $1->getType());
        $$->setDataType($1->getDataType());
        logFile << "Line " << line_count << ": factor : variable INCOP\n" << $$->getName() << endl;
    }
    | variable DECOP    {
        $$ = new SymbolInfo($1->getName()+"--", $1->getType());
        $$->setDataType($1->getDataType());
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

        $$->asmText = $1->asmText + "," + $3->asmText;
        $$->asmCode = $3->asmCode + "\n";
        if($3->offset != "") $$->asmCode += "PUSH " + stk_address($3->offset) + "\n";
        else $$->asmCode += "PUSH " + $3->text + "\n";

        $$->code += $1->code;
    }
    | logic_expression  {
        $$ = $1;
        $$->asmCode = $1->asmCode + "\n";
        logFile << "Line " << line_count << ": arguments : logic_expression\n" << $$->getName() << endl;

        if($$->stk_offset != "") $$->code += "PUSH " + stk_address($$->offset);
        else $$->code += "PUSH " + $1->asmText + "\n";
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
    asmFile.open("1805021_code.asm", ios::out);
    optimizedFile.open("1805021_optimized.asm", ios::out);

    dataVars.push_back("IS_NEG DB ?");
    dataVars.push_back("FOR_PRINT DW ?");
    dataVars.push_back("CR EQU 0DH\nLF EQU 0AH\nNEWLINE DB CR, LF , '$'");

    yyin = fin;
    yyparse();
    fclose(yyin);

    symbolTable.printAllScopeTables(logFile);
    logFile << endl;
    logFile << "Total lines: " << line_count << endl;
    logFile << "Total errors: " << error_count << endl;

    logFile.close();
    errorFile.close();
    asmFile.close();
    optimizedFile.close();

    exit(0);
}
