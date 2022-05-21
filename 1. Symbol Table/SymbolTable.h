#include <stack>
#include "ScopeTable.h"

using namespace std;

class SymbolTable{
        int total_buckets;
        ScopeTable* curr;
        stack<ScopeTable*> scopeStack;
    public:
        SymbolTable();
        SymbolTable(int total_buckets);
        void enterScope();
        void exitScope();
        bool insert(string name, string type);
        bool remove(string name);
        SymbolInfo* lookup(string name);
        void printCurrentScopeTable();
        void printAllScopeTables();
};

SymbolTable::SymbolTable(){}

SymbolTable::SymbolTable(int total_buckets){
    this->total_buckets = total_buckets;
    this->curr = new ScopeTable(this->total_buckets);
    this->scopeStack.push(this->curr);
}

void SymbolTable::enterScope(){
    ScopeTable* newScope = new ScopeTable(this->total_buckets);
    this->scopeStack.push(newScope);
    newScope->setParentScope(this->curr);
    this->curr = newScope;

    cout << "New ScopeTable with id " << this->curr->getId() << " created" << endl;
}

void SymbolTable::exitScope(){
    ScopeTable* deletedTable = this->scopeStack.top();
    this->scopeStack.pop();
    this->curr = this->scopeStack.top();
    this->curr->setDeletedId(this->curr->getDeletedId() + 1);

    cout << "ScopeTable with id " << deletedTable->getId() << " removed" << endl;
    delete deletedTable;
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
        if(this->curr->getParentScope() == NULL) return NULL;
        this->curr = this->curr->getParentScope();
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
