#include <stack>
#include "ScopeTable.h"

using namespace std;

class SymbolTable{
        int total_buckets;
        ScopeTable* curr;
        stack<ScopeTable*> scopeStack;
    public:
        SymbolTable(int total_buckets);
        void enterScope();
        void exitScope();
        bool insert(string name, string type);
        bool remove(string name);
        SymbolInfo* lookup(string name);
        void printCurrentScopeTable();
        void printAllScopeTables();
};

SymbolTable::SymbolTable(int total_buckets){
    this->total_buckets = total_buckets;
}

void SymbolTable::enterScope(){
    ScopeTable* newScope = new ScopeTable(this->total_buckets);
    this->scopeStack.push(newScope);
    newScope->parentScope = this->curr;
    this->curr = newScope;
}

void SymbolTable::exitScope(){
    this->scopeStack.pop();
    this->curr = this->scopeStack.top();
}

bool SymbolTable::insert(string name, string type){
    return this->curr->insert(name, type);
}

bool SymbolTable::remove(string name){
    return this->curr->deleteEntry(name);
}

SymbolInfo* SymbolTable::lookup(string name){
    while(true){
        SymbolInfo* temp = this->curr->lookup(name);
        if(temp != NULL) return temp;
        if(this->curr->parentScope == NULL) return NULL;
        this->curr = this->curr->parentScope;
    }
}

void SymbolTable::printCurrentScopeTable(){
    this->curr->print();
}

void SymbolTable::printAllScopeTables(){
    stack<ScopeTable*> tempStack = this->scopeStack;
    while(!tempStack.empty()){
        tempStack.top()->print();
        tempStack.pop();
    }
}
