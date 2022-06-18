%{
 #include <bits/stdc++.h>
 #include "1805021_SymbolTable.h"
 
 extern FILE *yyin;

 #define BUCKETS 7

 void yyerror(char *s){
     printf("%s\n",s);
 }

 int yylex(void);

 fstream logFile;
 SymbolTable symbolTable(BUCKETS);

%}

%union{
    SymbolInfo* si;
}

%token<si> ADDOP ID MULOP CONST_INT CONST_FLOAT CONST_CHAR
%token IF ELSE WHILE FOR NUMBER INT FLOAT VOID PRINTLN RETURN
%token NOT ASSIGNOP RELOP LPAREN RPAREN COMMA SEMICOLON LOGICOP INCOP DECOP LCURL RCURL LTHIRD RTHIRD

// Precedence: LOWER_THAN_ELSE < ELSE. Higher precedence, lower position
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%
start: program;

program: program unit
    | unit
    ;

unit: var_declaration
    | func_declaration
    | func_definition
    ;

func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
    | type_specifier ID LPAREN RPAREN SEMICOLON
    ;

func_definition: type_specifier ID LPAREN parameter_list RPAREN compound_statement  { 
        symbolTable.enterScope();    
    }
    | type_specifier ID LPAREN RPAREN compound_statement    { 
        symbolTable.enterScope();    
    }
    ;

parameter_list: parameter_list COMMA type_specifier ID
    | parameter_list COMMA type_specifier
    | type_specifier ID
    | type_specifier
    ;

compound_statement: LCURL statements RCURL
    | LCURL RCURL
    ;

var_declaration: type_specifier declaration_list SEMICOLON
    ;

type_specifier: INT {  }
    | FLOAT
    | VOID
    ;

declaration_list: declaration_list COMMA ID
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    | ID    { symbolTable.insert($1->getName(), "ID"); }
    | ID LTHIRD CONST_INT RTHIRD
    ;

statements: statement
    | statements statement
    ;

statement: var_declaration
    | expression_statement
    | compound_statement
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
    | IF LPAREN expression RPAREN expression    %prec LOWER_THAN_ELSE
    | IF LPAREN expression RPAREN expression ELSE statement
    | WHILE LPAREN expression RPAREN statement
    | PRINTLN LPAREN ID RPAREN SEMICOLON
    | RETURN expression SEMICOLON
    ;

expression_statement: SEMICOLON
    | expression SEMICOLON
    ;

variable: ID    { symbolTable.insert($1->getName(), "ID"); }
    | ID LTHIRD expression RTHIRD
    ;

expression: logic_expression
    | variable ASSIGNOP logic_expression
    ;

logic_expression: rel_expression
    | rel_expression LOGICOP rel_expression
    ;

rel_expression: simple_expression
    | simple_expression RELOP simple_expression
    ;

simple_expression: term
    | simple_expression ADDOP term
    ;

term: unary_expression
    | term MULOP unary_expression
    ;

unary_expression: ADDOP unary_expression
    | NOT unary_expression
    | factor
    ;

factor: variable
    | ID LPAREN argument_list RPAREN
    | LPAREN expression RPAREN
    | CONST_INT { cout << yylval.si->getName() << endl; }
    | CONST_FLOAT
    | variable INCOP
    | variable DECOP
    ;

argument_list: arguments
    |
    ;

arguments: arguments COMMA logic_expression
    | logic_expression
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
