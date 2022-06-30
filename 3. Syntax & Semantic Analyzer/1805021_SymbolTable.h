#include <stack>
#include <fstream>
#include "1805021_ScopeTable.h"

using namespace std;

class SymbolTable{
        int total_buckets;
        ScopeTable* curr;
        stack<ScopeTable*> scopeStack;
    public:
        SymbolTable();
        SymbolTable(int total_buckets);
        ~SymbolTable();
        void enterScope();
        void exitScope();
        bool insert(SymbolInfo* symbolInfo);
        bool remove(string name);
        SymbolInfo* lookup(string name);
        void printCurrentScopeTable();
        void printAllScopeTables(fstream& logFile);
};

SymbolTable::SymbolTable(){
    this->curr = NULL;
}

SymbolTable::SymbolTable(int total_buckets){
    this->total_buckets = total_buckets;
    this->curr = new ScopeTable(this->total_buckets);
    this->scopeStack.push(this->curr);
}

SymbolTable::~SymbolTable(){
    while(!this->scopeStack.empty()){
        ScopeTable* temp = this->scopeStack.top();
        this->scopeStack.pop();
        if(temp) delete temp;
    }
}

void SymbolTable::enterScope(){
    ScopeTable* newScope = new ScopeTable(this->total_buckets);
    this->scopeStack.push(newScope);
    newScope->setParentScope(this->curr);
    this->curr = newScope;
}

void SymbolTable::exitScope(){
    if(this->scopeStack.empty()){
        return;
    }

    ScopeTable* deletedTable = this->scopeStack.top();
    this->scopeStack.pop();

    if(!this->scopeStack.empty()){
        this->curr = this->scopeStack.top();
        this->curr->setDeletedId(this->curr->getDeletedId() + 1);
    }else{
        this->curr = NULL;
    }

    delete deletedTable;
}

bool SymbolTable::insert(SymbolInfo* symbolInfo){
    if(this->scopeStack.empty()){
        this->curr = new ScopeTable(this->total_buckets);
        this->scopeStack.push(this->curr);
    }
    
    return this->curr->insert(symbolInfo);
}

bool SymbolTable::remove(string name){
    if(this->scopeStack.empty()){
        return false;
    }
    return this->curr->deleteEntry(name);
}

SymbolInfo* SymbolTable::lookup(string name){
    if(this->scopeStack.empty()){
        return NULL;
    }

    SymbolInfo* res = NULL;
    while(true){
        SymbolInfo* temp = this->curr->lookup(name);
        if(temp != NULL){
            res = temp;
            break;
        }
        if(this->curr->getParentScope() == NULL){
            res = NULL;
            break;
        }
        this->curr = this->curr->getParentScope();
    }

    if(res == NULL){
        
    }

    return res;
}

void SymbolTable::printCurrentScopeTable(){
    if(this->scopeStack.empty()){
        return;
    }

    //this->curr->print();
}

void SymbolTable::printAllScopeTables(fstream& logFile){
    if(this->scopeStack.empty()){
        logFile << "NO SCOPE AVAILABLE" << endl;
        return;
    }

    stack<ScopeTable*> tempStack = this->scopeStack;
    while(!tempStack.empty()){
        tempStack.top()->print(logFile);
        tempStack.pop();
    }
}
