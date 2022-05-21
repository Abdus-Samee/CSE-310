#include <iostream>
#include <string>
#include "SymbolInfo.h"

using namespace std;

class ScopeTable{
        int total_buckets;
        string id;
        SymbolInfo** ptr;
    public:
        ScopeTable* parentScope;
        ScopeTable(int total_buckets);
        bool insert(string name, string type);
        SymbolInfo* lookup(string name);
        bool deleteEntry(string name);
        void print();
        int sdbmHash(string name);
};

ScopeTable::ScopeTable(int total_buckets){
    this->total_buckets = total_buckets;
    ptr = new SymbolInfo*[total_buckets];
}

bool ScopeTable::insert(string name, string type){
    int hash_value = sdbmHash(name);

    if(ptr[hash_value] == NULL){
        ptr[hash_value] = new SymbolInfo(name, type);
        return true;
    }else{
        SymbolInfo* temp = ptr[hash_value];
        while(temp->next != NULL){
            if(temp->getName() == name) return false;
            temp = temp->next;
        }
        temp->next = new SymbolInfo(name, type);
        return true;
    }
}

SymbolInfo* ScopeTable::lookup(string name){
    int hash_value = sdbmHash(name);

    if(ptr[hash_value] == NULL) return NULL;
    else{
        SymbolInfo* temp = ptr[hash_value];
        while(temp->next != NULL){
            if(temp->getName() == name) return temp;
            temp = temp->next;
        }

        if(temp->getName() == name) return temp;

        return NULL;
    }
}

bool ScopeTable::deleteEntry(string name){
    int hash_value = sdbmHash(name);

    if(ptr[hash_value] == NULL) return false;
    else{
        SymbolInfo* temp = ptr[hash_value];

        if(temp->getName() == name){
            ptr[hash_value] = temp->next;
            delete temp;
            return true;
        }else{
            while(temp->next != NULL){
                if(temp->next->getName() == name){
                    SymbolInfo* temp2 = temp->next;
                    temp->next = temp->next->next;
                    delete temp2;
                    return true;
                }
                temp = temp->next;
            }
        }
    }

    return false;
}

void ScopeTable::print(){
    cout << "Scope Table # ?.?.?\n";
    
    for(int i = 0; i < total_buckets; i++){
        if(ptr[i] != NULL){
            SymbolInfo* temp = ptr[i];
            cout << i << " --> ";
            while(temp != NULL){
                cout << "< " << temp->getName() << " : " << temp->getType() << " >  ";
                temp = temp->next;
            }
            cout << "\n";
        }else cout << i << " -->\n";
    }
}

int ScopeTable::sdbmHash(string name){
    int hash = 0;
    for(int i = 0; i < name.length(); i++){
        hash = name[i] + (hash << 6) + (hash << 16) - hash;
    }
    return hash % total_buckets;
}
