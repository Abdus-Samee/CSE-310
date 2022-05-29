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

    fstream outputFile;
    outputFile.open("1805021_output.txt", ios::out | ios::app);
    outputFile << "New ScopeTable with id " << this->curr->getId() << " created" << endl;
    outputFile.close();
}

void SymbolTable::exitScope(){
    if(this->scopeStack.empty()){
        cout << "NO CURRENT SCOPE" << endl;
        fstream outputFile;
        outputFile.open("1805021_output.txt", ios::out | ios::app);
        outputFile << "NO CURRENT SCOPE" << endl;
        outputFile.close();

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

    cout << "ScopeTable with id " << deletedTable->getId() << " removed" << endl;

    fstream outputFile;
    outputFile.open("1805021_output.txt", ios::out | ios::app);
    outputFile << "ScopeTable with id " << deletedTable->getId() << " removed" << endl;
    outputFile.close();

    delete deletedTable;
}

bool SymbolTable::insert(string name, string type){
    if(this->scopeStack.empty()){
        this->curr = new ScopeTable(this->total_buckets);
        this->scopeStack.push(this->curr);
    }
    return this->curr->insert(name, type);
}

bool SymbolTable::remove(string name){
    if(this->scopeStack.empty()){
        cout << "NO SCOPE TO REMOVE FROM" << endl;
        fstream outputFile;
        outputFile.open("1805021_output.txt", ios::out | ios::app);
        outputFile << "NO SCOPE TO REMOVE FROM" << endl;
        outputFile.close();

        return false;
    }
    return this->curr->deleteEntry(name);
}

SymbolInfo* SymbolTable::lookup(string name){
    if(this->scopeStack.empty()){
        cout << "NO SCOPE TO LOOKUP FROM" << endl;
        fstream outputFile;
        outputFile.open("1805021_output.txt", ios::out | ios::app);
        outputFile << "NO SCOPE TO LOOKUP FROM" << endl;
        outputFile.close();

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
        cout << "Not found\n";

        fstream outputFile;
        outputFile.open("1805021_output.txt", ios::out | ios::app);
        outputFile << "Not found" << endl;
        outputFile.close();
    }

    return res;
}

void SymbolTable::printCurrentScopeTable(){
    if(this->scopeStack.empty()){
        cout << "NO CURRENT SCOPE" << endl;
        fstream outputFile;
        outputFile.open("1805021_output.txt", ios::out | ios::app);
        outputFile << "NO CURRENT SCOPE" << endl;
        outputFile.close();

        return;
    }

    this->curr->print();
}

void SymbolTable::printAllScopeTables(){
    if(this->scopeStack.empty()){
        cout << "NO SCOPE AVAILABLE" << endl;
        fstream outputFile;
        outputFile.open("1805021_output.txt", ios::out | ios::app);
        outputFile << "NO SCOPE AVAILABLE" << endl;
        outputFile.close();

        return;
    }

    stack<ScopeTable*> tempStack = this->scopeStack;
    while(!tempStack.empty()){
        tempStack.top()->print();
        tempStack.pop();
    }
}
