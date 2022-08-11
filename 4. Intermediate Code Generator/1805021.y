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
 string param_code = "";
 string cur_function_name = "";

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

 void incrementSP(int width = -1){
    if(width == -1) sp += 2;
    else sp += width*2;
 }

 string newTemp() {
	string temp = "temp_" + to_string(tempCount++);
	incrementSP();
	return temp;
 }

 string newLabel() {
    return "label_" + to_string(labelCount++);
 }

 string defineWord(string word){
  return word + " dw ?";
 }

 string getAssemblyForJump(string relop){
    if(relop == "==") return "je";
    else if(relop == ">") return "jg";
    else if(relop == "<") return "jl";
    else if(relop == ">=") return "jge";
    else if(relop == "<=") return "jle";
    else if(relop == "!=") return "jne";
 }

 string getStackAddress(string offset){
    return "[bp-"+offset+"]";
 }

 string getStackAddressOfParameter(string offset){
    return "[bp+"+offset+"]";
 }

 string getStackAddress_typecast(string offset){
    return "WORD PTR [bp-"+offset+"]";
 }

 string getCurrFuncLabel(string name){
    return "L_" + name;
 }

 string getGlobalAddress(string str){
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

 vector<string> tokenize(string str, char delim){
    vector<string> ans;

    size_t start;
    size_t end = 0;

    while ((start = str.find_first_not_of(delim, end)) != string::npos)
    {
        end = str.find(delim, start);
        ans.push_back(str.substr(start, end - start));
    }

    return ans;
 }

 void codeOptimization(string code){
    vector<string>line_v  = tokenize(code,'\n');
    int line_v_sz = line_v.size();

    string prev_line_cmd = "";
    vector<string>prev_line_token;

    for(int i=0;i<line_v_sz;i++){
        string cur_line = line_v[i];
        vector<string>cur_line_token;

        if(cur_line[0] == ';'){
            optimizedFile << cur_line << endl;
            continue;
        }

        vector<string>token_v = tokenize(cur_line,' ');

        if(token_v[0] == "MOV" || token_v[0] == "mov")
        {

            if(token_v[1] == "WORD"){
                cur_line_token = tokenize(token_v[3],',');
            }else{
                cur_line_token = tokenize(token_v[1],',');
            }

            if(prev_line_cmd == "MOV" || prev_line_cmd == "mov"){
                
                if(i>0){
                    if(cur_line_token[0] == prev_line_token[1] && cur_line_token[1] == prev_line_token[0]){
                        
                    }else{
                        optimizedFile << cur_line << endl;
                    }
                }else{
                    optimizedFile << cur_line << endl;
                }
            }else{
               optimizedFile << cur_line << endl; 
            }

            prev_line_token = cur_line_token;

        }else{

            int sz_token_v = token_v.size();

            if(sz_token_v >= 2){
                if(token_v[1] == "PROC")
                    optimizedFile << endl;
            }

            optimizedFile << cur_line << endl;
            prev_line_token.clear();
        }
        
        prev_line_cmd = token_v[0];
        
    }
 }

 bool isTemp(string s){
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

   if(error_count == 0){
    string header = ".MODEL SMALL\n\n.STACK 100H";
    string print_str = "";
    print_str += "\r\nPRINT_TO_CONSOLE PROC\r\n               ";
    print_str += "\r\n        MOV CX , 0FH     \r\n        PUSH CX ; marker\r\n        \r\n        MOV IS_NEG, 0H\r\n        ";
    print_str += "MOV AX , FOR_PRINT\r\n        TEST AX , 8000H\r\n        JE PRINT_TO_CONSOLE_LOOP\r\n                    \r\n        ";
    print_str += "MOV IS_NEG, 1H\r\n        MOV AX , 0FFFFH\r\n        SUB AX , FOR_PRINT\r\n        ADD AX , 1H\r\n        ";
    print_str += "MOV FOR_PRINT , AX\r\n\r\n    PRINT_TO_CONSOLE_LOOP:\r\n    \r\n        ;MOV AH, 1\r\n        ;INT 21H\r\n        \r\n        ";
    print_str += "MOV AX , FOR_PRINT\r\n        XOR DX,DX\r\n        MOV BX , 10D\r\n        DIV BX ; QUOTIENT : AX  , REMAINDER : DX     ";
    print_str += "\r\n        \r\n        MOV FOR_PRINT , AX\r\n        \r\n        PUSH DX\r\n        \r\n        CMP AX , 0H\r\n        ";
    print_str += "JNE PRINT_TO_CONSOLE_LOOP\r\n        \r\n        ;LEA DX, NEWLINE ; DX : USED IN IO and MUL,DIV\r\n        ;MOV AH, 9 ; AH,9 used for character string output\r\n";
    print_str += "        ;INT 21H;\r\n\r\n        MOV AL , IS_NEG\r\n        CMP AL , 1H\r\n        JNE OP_STACK_PRINT\r\n        \r\n        ";
    print_str += "MOV AH, 2\r\n        MOV DX, '-' ; stored in DL for display \r\n        INT 21H\r\n            \r\n        \r\n    ";
    print_str += "OP_STACK_PRINT:\r\n    \r\n        ;MOV AH, 1\r\n        ;INT 21H\r\n    \r\n        POP BX\r\n        \r\n        ";
    print_str += "CMP BX , 0FH\r\n        JE EXIT_PRINT_TO_CONSOLE\r\n        \r\n       \r\n        MOV AH, 2\r\n        MOV DX, BX ; stored in DL for display \r\n";
    print_str += "        ADD DX , 30H\r\n        INT 21H\r\n        \r\n        JMP OP_STACK_PRINT\r\n\r\n    EXIT_PRINT_TO_CONSOLE:\r\n    \r\n        ";
    print_str += ";POP CX \r\n\r\n        LEA DX, NEWLINE\r\n        MOV AH, 9 \r\n        INT 21H\r\n    \r\n        RET     \r\n      ";
    print_str += "\r\nPRINT_TO_CONSOLE ENDP";
    
    asmFile << header << endl;
    asmFile << ".DATA" << endl;
    for(auto dv : dataVars) asmFile << dv << endl;
    asmFile << endl;
    asmFile << ".CODE" << endl;
    asmFile << print_str << endl;
    asmFile << "\n" << $$->asmCode << "\n" << endl;

    optimizedFile << header << endl;
    optimizedFile << ".DATA" << endl;
    for(auto dv : dataVars) optimizedFile << dv << endl;
    optimizedFile << endl;
    optimizedFile << ".CODE" << endl;
    optimizedFile << print_str << "\n\n" << endl;
    codeOptimization($$->asmCode);
   }
};

program: program unit   {
        $$ = new SymbolInfo($1->getName()+"\n"+$2->getName(), "program");
        logFile << "Line " << line_count << ": program: program unit\n" << $$->getName() << endl;

        $$->asmText = $1->asmText + "\n" + $2->asmText;
        $$->offset = $1->offset;
        $$->tempVar = $1->tempVar;
        $$->asmCode = $1->asmCode + $2->asmCode;
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

        $$->offset = $1->offset;
        $$->asmText = $1->asmText;
        $$->asmCode = $1->asmCode;
        $$->tempVar = $1->tempVar;
        sp = 0;
    }
    | func_definition   {
        $$ = new SymbolInfo($1->getName(), "unit");
        logFile << "Line " << line_count << ": unit: func_definition\n" << $$->getName() << endl;

        $$->offset = $1->offset;
        $$->asmText = $1->asmText;
        $$->asmCode = $1->asmCode;
        $$->tempVar = $1->tempVar;
        sp = 0;
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

        $$->asmText = $1->asmText + " " + $2->getName() + "(" + $4->asmText + ");";
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

        $$->asmText = $1->asmText + " " + $2->getName() + "();";
    }
    ;

func_definition: type_specifier ID LPAREN parameter_list RPAREN { 
        string name = $2->getName();
        cur_function_name = name;
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
            int param_val = 4;
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
                    incrementSP();
                    temp->offset = to_string(sp);

                    if(!symbolTable.insert(temp)){
                        error_count++;
                        errorFile << "Error at line " << line_count << ": Multiple declaration of " << varName << " in parameter" << endl;
                        logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN parameter_list RPAREN\n";
                        logFile << "Error at line " << line_count << ": Multiple declaration of " << varName << " in parameter" << endl;
                    }

                    param_code += "MOV AX, " + getStackAddressOfParameter(to_string(param_val))+"\n";
                    param_code += "MOV "  +getStackAddress_typecast(temp->offset) + ", AX\n";
                    param_val+=2;
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
                    int param_val = 4;
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
                        incrementSP();
                        temp->offset = to_string(sp);

                        if(!symbolTable.insert(temp)){
                            error_count++;
                            errorFile << "Error at line " << line_count << ": Multiple declaration of " << varName << endl;
                            logFile << "Line " << line_count << ": func_definition: type_specifier ID LPAREN parameter_list RPAREN\n";
                            logFile << "Error at line " << line_count << ": Multiple declaration of " << varName << endl;
                        }

                        param_code += "MOV AX, " + getStackAddressOfParameter(to_string(param_val))+"\n";
                        param_code += "MOV "  +getStackAddress_typecast(temp->offset) + ", AX\n";
                        param_val+=2;
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

        $$->asmText = $1->asmText + " " + $2->getName() + "(" + $4->asmText + ")" + $7->asmText;
        $$->asmCode = $2->getName() + " PROC\n";
        
        if($2->getName() == "main") $$->asmCode += "MOV AX, @DATA\nMOV DS, AX\n";

        $$->asmCode += "PUSH BP\nMOV BP,SP\n";
        $$->asmCode += "SUB SP, " + to_string(sp) + "\n";
        $$->asmCode += $4->asmCode + "\n";
        $$->asmCode += param_code + "\n";
        $$->asmCode += $7->asmCode + "\n";
        $$->asmCode += "L_" + $2->getName() + ":\n";
        $$->asmCode += "ADD SP, " + to_string(sp) + "\n";
        $$->asmCode += "POP BP\n";

        param_code = "";

        if($2->getName() == "main"){
            $$->asmCode += "\n;DOS EXIT\nMOV AH, 4CH\nINT 21H\n";
        }else {
            $$->asmCode += "RET\n";
        }

        $$->asmCode += $2->getName() + " ENDP\n\n";

        if($2->getName() == "main") $$->asmCode += "END MAIN\n";
    }
    | type_specifier ID LPAREN RPAREN   { 
        string type = "func_definition";
        string name = $2->getName();
        cur_function_name = name;
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

        $$->asmText = $1->asmText + " " + $2->getName() + "()" + $6->asmText;
        $$->asmCode = $2->getName() + " PROC\n";

        if($2->getName() == "main"){
            $$->asmCode += "MOV AX, @DATA\nMOV DS, AX\n";
        }

        $$->asmCode += "PUSH BP\nMOV BP, SP\n";
        $$->asmCode += "SUB SP, " + to_string(sp) + "\n";

        $$->asmCode += $6->asmCode + "\n";

        $$->asmCode += "L_" + $2->getName() + ":\n";
        $$->asmCode += "ADD SP, " + to_string(sp) + "\n";
        $$->asmCode += "POP BP\n";

        if($2->getName() == "main"){
            $$->asmCode += "\n;DOS EXIT\nMOV AH, 4CH\nINT 21H\n";
        }else{
            $$->asmCode += "RET\n";
        }
        

        $$->asmCode += $2->getName() + " ENDP\n";

        if($2->getName() == "main") $$->asmCode += "END MAIN\n";
    }
    ;

parameter_list: parameter_list COMMA type_specifier ID  {
        $$ = new SymbolInfo($1->getName()+","+$3->getName()+" "+$4->getName(), "parameter_list");
        logFile << "Line " << line_count << ": parameter_list: parameter_list COMMA type_specifier ID\n" << $$->getName() << endl;

        $$->asmText = $1->asmText + "," + $3->asmText + " " + $4->getName();
    }
    | parameter_list COMMA type_specifier   {
        $$ = new SymbolInfo($1->getName()+","+$3->getName(), "parameter_list");
        logFile << "Line " << line_count << ": parameter_list: parameter_list COMMA type_specifier\n" << $$->getName() << endl;

        $$->asmText = $1->asmText + "," + $3->getName();
    }
    | type_specifier ID {
        $$ = new SymbolInfo($1->getName()+" "+$2->getName(), "parameter_list");
        logFile << "Line " << line_count << ": parameter_list: type_specifier ID\n" << $$->getName() << endl;

        $$->asmText = $1->asmText + " " + $2->getName();
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
        $$->asmText = "{\n" + $2->asmText + "\n}";
        $$->asmCode = $2->asmCode;
        $$->offset = $2->offset;
        $$->tempVar = $2->tempVar;
        logFile << "Line " << line_count << ": compound_statement: LCURL statements RCURL\n" << $$->getName() << endl;
        symbolTable.printAllScopeTables(logFile);
        symbolTable.exitScope();
    }
    | LCURL RCURL   {
        symbolTable.printAllScopeTables(logFile);
        symbolTable.exitScope();
        $$ = new SymbolInfo("{}", "compound_statement");
        logFile << "Line " << line_count << ": compound_statement: LCURL RCURL\n" << $$->getName() << endl;

        $$->asmText = "{}";
    }
    ;

var_declaration: type_specifier declaration_list SEMICOLON  {
        $$ = new SymbolInfo($1->getName()+" "+$2->getName()+";", "var_declaration");
        vector<string> splitted = splitString($2->getName(), ',');

        $$->asmText = $1->asmText + " " + $2->asmText + ";";
        
        if($1->getName() == "void"){
            error_count++;
            errorFile << "Error at line " << line_count << ": Variable type cannot be void\n";
            logFile << "Line " << line_count << ": var_declaration : type_specifier declaration_list SEMICOLON\n";
        }else{
            for(string s : splitted){
                SymbolInfo* variable;

                if(isVarArray(s)){
                    string name = getArrayName(s);
                    string len = getArrayLength(s);
                    variable = new SymbolInfo(name, $2->getType());
                    variable->setArrayLength(len);
                    variable->setDataType($1->getName());

                    if(symbolTable.getCurrentTableID() == "1"){
                        dataVars.push_back(name + " DW " + len + " DUP ($)");
                    }else{
                        int num = stoi(len);
                        incrementSP(num);
                        variable->offset = to_string(sp);
                    }
                }else{
                    variable = new SymbolInfo(s, $1->getName());
                    //variable->setDataType($1->getName());

                    if(symbolTable.getCurrentTableID() == "1"){
                        dataVars.push_back(s + " DW ?");
                    }else{
                        incrementSP(2);
                        variable->offset = to_string(sp);
                    }
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
        $$->asmText = "INT";
        logFile << "Line " << line_count << ": type_specifier : INT\nint\n"; 
    }
    | FLOAT { 
        $$ = new SymbolInfo("float", "float");
        $$->asmText = "FLOAT";
        logFile << "Line " << line_count << ": type_specifier : FLOAT\nfloat\n"; 
    }
    | VOID  { 
        $$ = new SymbolInfo("void", "void");
        $$->asmText = "VOID";
        logFile << "Line " << line_count << ": type_specifier : VOID\nvoid\n"; 
    }
    ;

declaration_list: declaration_list COMMA ID {
        $$ = new SymbolInfo($1->getName()+","+$3->getName(), $3->getType());
        logFile << "Line " << line_count << ": declaration_list : declaration_list COMMA ID\n" << $$->getName() << endl;

        $$->asmText = $1->asmText + "," + $3->getName();
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
        $$ = new SymbolInfo($1->getName()+","+$3->getName()+"["+$5->getName()+"]", "declaration_list");
        logFile << "Line " << line_count << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n" << $$->getName() << endl;

        $$->asmText = $1->asmText + "," + $3->getName() + "[" + $5->getName() + "]";
    }
    | ID    {
        $$ = new SymbolInfo($1->getName(), $1->getType());
        logFile << "Line " << line_count << ": declaration_list : ID\n" << $1->getName() << endl;

        $$->asmText = $1->getName();
    }
    | ID LTHIRD CONST_INT RTHIRD    {
        $$ = new SymbolInfo($1->getName()+"["+$3->getName()+"]", "ID");
        logFile << "Line " << line_count << ": declaration_list : ID LTHIRD CONST_INT RTHIRD\n" << $$->getName() << endl;

        $$->asmText = $1->getName() + "[" + $3->getName() + "]";
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
        logFile << "Line " << line_count << ": statements : statements statement\n" << $$->getName() << endl;
        $$->asmText = $1->asmText + "\n" + $2->asmText;
        $$->asmCode = $1->asmCode + "\n" + $2->asmCode;
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
        $$->asmCode += "CMP " + getStackAddress($4->offset) + ", 0\n"; // check if need to exit
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
        $$->asmCode += "CMP " + getStackAddress($3->offset) + ", 0\n";
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

        $$->asmCode += "CMP " + getStackAddress($3->offset) + ", 0\n";
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

        $$->asmText = "while(" + $3->asmText + ") " + $5->asmText;
        string t1 = newLabel();
        string t2 = newLabel();

        string to_print = $$->asmText;
        to_print.erase(remove(to_print.begin(), to_print.end(), '\n'), to_print.end());

        $$->asmCode = "; " + to_print + "\n";

        $$->asmCode += t1 + ":\n"; // loop starting label

        $$->asmCode += "; " + $3->asmText + "\n";
        $$->asmCode += $3->asmCode + "\n"; // eval expression

        $$->asmCode += "; check while loop condition\n";
        $$->asmCode += "CMP " + getStackAddress($3->offset) + ", 0\n"; // check if need to exit
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
            
        if(var != NULL && var->offset != "") $$->asmCode += "MOV AX, " + getStackAddress(var->offset) + "\n";
        else $$->asmCode += "MOV AX, " + $3->getName() + "\n";
        
        $$->asmCode += "MOV FOR_PRINT, AX\n";
        $$->asmCode += "CALL PRINT_TO_CONSOLE";
    }
    | RETURN expression SEMICOLON   {
        $$ = new SymbolInfo("return "+$2->getName() + ";", $2->getType());
        logFile << "Line " << line_count << ": statement : RETURN expression SEMICOLON\n" << $$->getName() << endl;

        $$->asmText = "return " + $2->asmText + ";";
        $$->asmCode = "; " + $$->asmText + "\n";
        $$->asmCode += $2->asmCode + "\n";

        if($2->offset != "") $$->asmCode += "MOV AX, " + getStackAddress($2->offset) + "\n";
        else{
            $$->asmCode += "MOV AX, " + getGlobalAddress($2->asmText) + "\n";
        } 

        $$->asmCode += "JMP " + getCurrFuncLabel(cur_function_name)+"\n";
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
        $$->asmText = $1->getName();

        if(var != NULL) $$->offset = var->offset;
    }
    | ID LTHIRD expression RTHIRD   { 
        string type = $1->getType();
        SymbolInfo* var = symbolTable.lookup($1->getName());

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

        $$->asmText = $1->getName() + "[" + $3->asmText + "]";

        if(var != NULL){
            $$->asmCode = $3->asmCode = "\n";

            if(var->offset != ""){
                $$->asmCode += "MOV SI, " + getStackAddress($3->offset) + "\n";
                $$->asmCode += "ADD SI, SI";
                $$->offset = var->offset + " + SI";
            }else{
                $$->asmCode += "MOV BX, " + getStackAddress($3->offset) + "\n";
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

        $$->asmText = $1->asmText + "=" + $3->asmText;
        $$->asmCode = $3->asmCode + "\n";

        if($3->offset != "") $$->asmCode += "MOV CX, " + getStackAddress($3->offset) + "\n";
        else $$->asmCode += "MOV CX, " + getGlobalAddress($3->asmText) + "\n";

        if($1->asmCode != "") $$->asmCode += $1->asmCode + "\n";

        if($1->offset != "") $$->asmCode += "MOV " + getStackAddress_typecast($1->offset) + ",CX";
        else $$->asmCode += "MOV " + getGlobalAddress($1->asmText) + ", CX";
    }
    ;

logic_expression: rel_expression    {
        $$ = $1;
        logFile << "Line " << line_count << ": logic_expression : rel_expression\n" << $$->getName() << endl;
    }
    | rel_expression LOGICOP rel_expression {
        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), "int");
        logFile << "Line " << line_count << ": logic_expression : rel_expression LOGICOP rel_expression\n" << $$->getName() << endl;

        $$->asmText = $1->asmText + $2->getName() + $3->asmText;

        if($2->getName() == "&&"){
            $$->asmCode = $1->asmCode + "\n" + $3->asmCode + "\n";

            if($1->offset != "") $$->asmCode += "CMP " + getStackAddress($1->offset) + ", 0\n";
            else  $$->asmCode += "CMP "+ getGlobalAddress($1->asmText) + ", 0\n";

            string t1 = newLabel();
            string t2 = newLabel();

            $$->asmCode += "JE " + t1 + "\n";

            if($3->offset != "") $$->asmCode += "CMP " + getStackAddress($3->offset) + ", 0\n";
            else $$->asmCode += "CMP " + getGlobalAddress($3->asmText) + ", 0\n";

            $$->asmCode += "JE " + t1 + "\n";

            if(isTemp($1->offset)){
                $$->offset = $1->offset;
            }else if(isTemp($3->offset)){
                $$->offset = $3->offset;
            }else{
                string tempVar = newTemp();

                $$->tempVar = tempVar;
                $$->offset = to_string(sp);
            }

            $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", 1\n";
            $$->asmCode += "JMP " + t2 + "\n";
            $$->asmCode += t1 + ":\n";
            $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", 0\n";
            $$->asmCode += t2 + ":\n";
            
        }else if($2->getName() == "||"){
            $$->asmCode = $1->asmCode + "\n" + $3->asmCode + "\n";

            if($1->offset != "") $$->asmCode += "CMP " + getStackAddress($1->offset) + ", 0\n";
            else  $$->asmCode += "CMP " + getGlobalAddress($1->asmText) + ", 0\n";

            string t1 = newLabel();
            string t2 = newLabel();

            $$->asmCode += "JNE " + t1 + "\n";

            if($3->offset != "") $$->asmCode += "CMP " + getStackAddress($3->offset) + ", 0\n";
            else $$->asmCode += "CMP " + getGlobalAddress($3->asmText) + ", 0\n";

            $$->asmCode += "JNE " + t1 + "\n";

            if(isTemp($1->offset)){
                $$->offset = $1->offset;
            }else if(isTemp($3->offset)){
                $$->offset = $3->offset;
            }else{
                string tempVar = newTemp();

                $$->tempVar = tempVar;
                $$->offset = to_string(sp);
            }

            $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", 0\n";
            $$->asmCode += "JMP " + t2 + "\n";
            $$->asmCode += t1 + ":\n";
            $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", 1\n";
            $$->asmCode += t2 + ":\n";

        }
    }
    ;

rel_expression: simple_expression   {
        $$ = $1;
        logFile << "Line " << line_count << ": rel_expression : simple_expression\n" << $$->getName() << endl;
    }
    | simple_expression RELOP simple_expression {
        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), "int");
        logFile << "Line " << line_count << ": rel_expression : simple_expression RELOP simple_expression\n" << $$->getName() << endl;

        $$->asmText = $1->asmText + $2->getName() + $3->asmText;
        $$->asmCode = $1->asmCode + "\n" + $3->asmCode + "\n";

        if($1->offset != "") $$->asmCode += "MOV AX, " + getStackAddress($1->offset) + "\n";
        else $$->asmCode += "MOV AX, " + getGlobalAddress($1->asmText) + "\n";

        if($3->offset != "") $$->asmCode += "CMP AX, " + getStackAddress($3->offset) + "\n";
        else $$->asmCode += "CMP AX, " + getGlobalAddress($3->asmText) + "\n";

        string t1 = newLabel();
        string t2 = newLabel();

        if(isTemp($1->offset)){
            $$->offset = $1->offset;
        }else if(isTemp($3->offset)){
            $$->offset = $3->offset;
        }else{
            string tempVar = newTemp();

            $$->tempVar = tempVar;
            $$->offset = to_string(sp);
        }

        string jumpText = getAssemblyForJump($2->getName());
        $$->asmCode += jumpText + " " + t1 + "\n";
        $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", 0" + "\n";
        $$->asmCode += "JMP " + t2 + "\n";
        $$->asmCode += t1 + ":\n";
        $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", 1" + "\n";
        $$->asmCode += t2 + ":\n";

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

        $$->asmText = $1->asmText + $2->getName() + $3->asmText;

        if($2->getName() == "+"){
            $$->asmCode = $1->asmCode + "\n";
            
            if($1->offset != "") $$->asmCode += "MOV AX, " + getStackAddress($1->offset) + "\n";
            else $$->asmCode += "MOV AX, " + getGlobalAddress($1->asmText) + "\n";

            string tempVarExtra = newTemp();
            string tempVarExtra_stk_add = to_string(sp);

            $$->asmCode += "MOV " + getStackAddress_typecast(tempVarExtra_stk_add) + ", AX\n";
            $$->asmCode += $3->asmCode + "\n";
            $$->asmCode += "MOV AX, " + getStackAddress(tempVarExtra_stk_add) + "\n";

            if($3->offset != "") $$->asmCode += "ADD AX, " + getStackAddress($3->offset) + "\n";
            else $$->asmCode += "ADD AX, " + getGlobalAddress($3->asmText) + "\n";

            if(isTemp($1->offset)){
                $$->offset = $1->offset;
            }else if(isTemp($3->offset)){
                $$->offset = $3->offset;
            }else{
                string tempVar = newTemp();

                $$->tempVar = tempVar;
                $$->offset = to_string(sp);
            }

            $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", AX";
        }else{
            $$->asmCode = $1->asmCode + "\n";
            
            if($1->offset != "") $$->asmCode += "MOV AX, " + getStackAddress($1->offset) + "\n";
            else $$->asmCode += "MOV AX, " + getGlobalAddress($1->asmText) + "\n";

            string tempVarExtra = newTemp();
            string tempVarExtra_stk_add = to_string(sp);

            $$->asmCode += "MOV " + getStackAddress_typecast(tempVarExtra_stk_add) + ", AX\n";

            $$->asmCode += $3->asmCode + "\n";
            
            $$->asmCode += "MOV AX, " + getStackAddress(tempVarExtra_stk_add) + "\n";
            
            if($3->offset != "") $$->asmCode += "SUB AX, " + getStackAddress($3->offset) + "\n";
            else $$->asmCode += "SUB AX, " + getGlobalAddress($3->asmText) + "\n";

            if(isTemp($1->offset)){
                $$->offset = $1->offset;
            }else if(isTemp($3->offset)){
                $$->offset = $3->offset;
            }else{
                string tempVar = newTemp();

                $$->tempVar = tempVar;
                $$->offset = to_string(sp);
            }

            $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", AX";
        }
    }
    ;

term: unary_expression  {
        $$ = $1;
        logFile << "Line " << line_count << ": term : unary_expression\n" << $$->getName() << endl;
    }
    | term MULOP unary_expression   {
        string type = "int";
        $$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), type);
        logFile << "Line " << line_count << ": term : term MULOP unary_expression\n" << $$->getName() << endl;
        if(($1->getDataType()=="float" || $1->getDataType()=="CONST_FLOAT") || ($3->getDataType()=="float" || $3->getDataType()=="CONST_FLOAT")) type="float";

        if(($2->getName() == "%") && ((($1->getType()=="CONST_INT")||($1->getType()=="int")) && (($3->getType()!="CONST_INT")&&($3->getType()!="int")))){
            error_count++; 
            type = "error";
            errorFile << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl;
            logFile << "Line " << line_count << ": term : term MULOP unary_expression\n";
            logFile << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl;
        }
        if(($2->getName() == "%") && ((($1->getType()=="CONST_INT")&&($1->getType()=="int")) && (($3->getType()!="CONST_INT")||($3->getType()!="int")))){
            error_count++; 
            type = "error";
            errorFile << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl;
            logFile << "Line " << line_count << ": term : term MULOP unary_expression\n";
            logFile << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << endl;
        }
        if(($2->getName() == "%") && $3->getName() == "0"){
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
            logFile << "Line " << line_count << ": term : term MULOP unary_expression\n";
            logFile << "Error at line " << line_count << ":  Void function used in expression\n";
        }
        
        if(($2->getName() == "%") && (type != "error")){
            logFile << "Line " << line_count << ": term : term MULOP unary_expression\n";

            $$->asmCode = $1->asmCode + "\n";
            

            if($1->offset != "") $$->asmCode += "MOV CX, " + getStackAddress($1->offset) + "\n";
            else $$->asmCode += "MOV CX, " + getGlobalAddress($1->asmText) + "\n";
            
            $$->asmCode += "CWD\n";

            string tempVarExtra = newTemp();
            string tempVarExtra_stk_add = to_string(sp);

            $$->asmCode += "MOV " + getStackAddress_typecast(tempVarExtra_stk_add) + ", CX\n";

            $$->asmCode += $3->asmCode + "\n";
            
            $$->asmCode += "MOV CX, " + getStackAddress(tempVarExtra_stk_add) + "\n";

            $$->asmCode += "MOV AX, CX\n";

            if($3->offset != "") $$->asmCode += "IDIV " + getStackAddress_typecast($3->offset) + "\n";
            else $$->asmCode += "IDIV " + getGlobalAddress($3->asmText) + "\n";

            if(isTemp($1->offset)){
                $$->offset = $1->offset;
            }else if(isTemp($3->offset)){
                $$->offset = $3->offset;
            }else{
                string tempVar = newTemp();
                $$->tempVar = tempVar;
                $$->offset = to_string(sp);
            }

            $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", DX";            
        }else if($2->getName() == "*"){
            $$->asmCode = $1->asmCode + "\n";

            if($1->offset != "") $$->asmCode += "MOV CX, " + getStackAddress($1->offset) + "\n";
            else $$->asmCode += "MOV CX, " + getGlobalAddress($1->asmText) + "\n";

            string tempVarExtra = newTemp();
            string tempVarExtra_stk_add = to_string(sp);

            $$->asmCode += "MOV " + getStackAddress_typecast(tempVarExtra_stk_add) + ", CX\n";
            $$->asmCode += $3->asmCode + "\n";
            $$->asmCode += "MOV CX, " + getStackAddress(tempVarExtra_stk_add) + "\n";
            $$->asmCode += "MOV AX, CX\n";

            if($3->offset != "") $$->asmCode += "IMUL " + getStackAddress_typecast($3->offset) + "\n";
            else $$->asmCode += "IMUL " + getGlobalAddress($3->asmText) + "\n";

            if(isTemp($1->offset)){
                $$->offset = $1->offset;
            }else if(isTemp($3->offset)){
                $$->offset = $3->offset;
            }else{
                string tempVar = newTemp();

                $$->tempVar = tempVar;
                $$->offset = to_string(sp);
            }

            $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", AX";
        }else if($2->getName() == "/"){
            $$->asmCode = $1->asmCode + "\n";

            if($1->offset!="") $$->asmCode += "MOV CX, " + getStackAddress($1->offset)+"\n";
            else $$->asmCode += "MOV CX, " + getGlobalAddress($1->asmText) + "\n";
            
            $$->asmCode += "CWD\n";

            string tempVarExtra = newTemp();
            string tempVarExtra_stk_add = to_string(sp);

            $$->asmCode += "MOV " + getStackAddress_typecast(tempVarExtra_stk_add) + ", CX\n";
            $$->asmCode += $3->asmCode + "\n";
            $$->asmCode += "MOV CX, " + getStackAddress(tempVarExtra_stk_add) + "\n";
            $$->asmCode += "MOV AX, CX\n";

            if($3->offset != "") $$->asmCode += "IDIV " + getStackAddress_typecast($3->offset) + "\n";
            else $$->asmCode += "IDIV " + getGlobalAddress($3->asmText) + "\n";

            if(isTemp($1->offset)){
                $$->offset = $1->offset;
            }else if(isTemp($3->offset))
            {
                $$->offset = $3->offset;
            }else{
                string tempVar = newTemp();

                $$->tempVar = tempVar;
                $$->offset = to_string(sp);
            }

            $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", AX";
        }

        $$->asmText = $1->asmText + $2->getName() + $3->asmText;
    }
    ;

unary_expression: ADDOP unary_expression    {
        $$ = new SymbolInfo(yylval.si->getName()+$2->getName(), $2->getType());
        logFile << "Line " << line_count << ": unary_expression : ADDOP unary_expression\n" << $$->getName() << endl;

        $$->asmText = $1->getName() + $2->asmText;

        if($1->getName() == "+"){
            $$->offset = $2->offset;
            $$->asmCode = $2->asmCode;
            $$->tempVar = $2->tempVar;
        }else{
            $$->tempVar = $2->tempVar;
            $$->offset = $2->offset;
            $$->asmCode = $2->asmCode + "\n" + "NEG " + getStackAddress_typecast($2->offset);
        }
    }
    | NOT unary_expression  {
        $$ = new SymbolInfo("!"+$2->getName(), $2->getType());
        logFile << "Line " << line_count << ": unary_expression : NOT unary_expression\n" << $$->getName() << endl;

        $$->asmText = "!" + $2->asmText;
        $$->asmCode = $2->asmCode + "\n" + "CMP " + getStackAddress($2->offset) + ", 0\n";;
        $$->offset = $2->offset;

        string t1 = newLabel();
        string t2 = newLabel();

        $$->asmCode += "JE " + t1 + "\n";
        $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", 0\n";
        $$->asmCode += "JMP " + t2 + "\n";
        $$->asmCode += t1 + ":\n";
        $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", 1\n";
        $$->asmCode += t2 + ":\n";

        $$->tempVar = $2->tempVar;
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
            $$->asmCode += "ADD SP, " + to_string(2*function->getParams().size());

            if(function->getFunctionReturnType() != "void"){
                $$->offset = to_string(sp);
                $$->asmCode += "\nMOV " + getStackAddress_typecast($$->offset) + ", AX";
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
        $$->asmCode = "MOV " + getStackAddress_typecast($$->offset) + ", " + $1->getName();
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

        $$->asmText = $1->asmText + "++";

        $$->tempVar = newTemp();
        $$->offset = to_string(sp); 
        $$->asmCode = $1->asmCode + "\n";

        if($1->offset != "") $$->asmCode += "MOV AX, " + getStackAddress($1->offset) + "\n";
        else $$->asmCode += "MOV AX, " + getGlobalAddress($1->asmText) + "\n";
        
        $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", AX\n";

        if($1->offset != "") $$->asmCode += "INC " + getStackAddress_typecast($1->offset);
        else $$->asmCode += "INC " + getGlobalAddress($1->asmText);
    }
    | variable DECOP    {
        $$ = new SymbolInfo($1->getName()+"--", $1->getType());
        $$->setDataType($1->getDataType());
        logFile << "Line " << line_count << ": factor : variable DECOP\n" << $$->getName() << endl;

        $$->asmText = $1->getName() + "--";
        $$->offset = $1->offset;
        $$->tempVar = $1->tempVar;
        $$->asmCode = "DEC " + getStackAddress_typecast($$->offset);

        $$->tempVar = newTemp();
        $$->offset = to_string(sp);
        $$->asmCode = $1->asmCode + "\n";

        if($1->offset != "") $$->asmCode += "MOV AX, " + getStackAddress($1->offset) + "\n";
        else $$->asmCode += "MOV AX, " + getGlobalAddress($1->asmText) + "\n";
        
        $$->asmCode += "MOV " + getStackAddress_typecast($$->offset) + ", AX\n";

        if($1->offset != "") $$->asmCode += "DEC " + getStackAddress_typecast($1->offset);
        else $$->asmCode += "DEC " + getGlobalAddress($1->asmText);
    }
    ;

argument_list: arguments    {
        $$ = $1;
        logFile << "Line " << line_count << ": argument_list : arguments\n" << $$->getName() << endl;
    }
    |   {
        $$ = new SymbolInfo("argument_list", "");
    }
    ;

arguments: arguments COMMA logic_expression {
        $$ = new SymbolInfo($1->getName()+","+$3->getName(), $1->getType()+","+$3->getType());
        logFile << "Line " << line_count << ": arguments : arguments COMMA logic_expression\n" << $$->getName() << endl;

        $$->asmText = $1->asmText + "," + $3->asmText;
        $$->asmCode = $3->asmCode + "\n";
        if($3->offset != "") $$->asmCode += "PUSH " + getStackAddress($3->offset) + "\n";
        else $$->asmCode += "PUSH " + $3->asmText + "\n";

        $$->asmCode += $1->asmCode;
    }
    | logic_expression  {
        $$ = $1;
        $$->asmCode = $1->asmCode + "\n";
        logFile << "Line " << line_count << ": arguments : logic_expression\n" << $$->getName() << endl;

        if($$->offset != "") $$->asmCode += "PUSH " + getStackAddress($$->offset);
        else $$->asmCode += "PUSH " + $1->asmText + "\n";
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
