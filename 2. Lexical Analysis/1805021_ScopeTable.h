#include <iostream>
#include <string>
#include <cstring>
#include <fstream>
#include "1805021_SymbolInfo.h"

using namespace std;

class ScopeTable{
        int total_buckets;
        string parent_id;
        int current_id;
        int deleted_id;
        ScopeTable* parentScope;
        SymbolInfo** ptr;
    public:
        ScopeTable(int total_buckets);
        ~ScopeTable();
        bool insert(string name, string type);
        SymbolInfo* lookup(string name);
        bool deleteEntry(string name);
        void print();
        int sdbmHash(string name);
        string getId();
        void setDeletedId(int id);
        int getDeletedId();
        void setParentScope(ScopeTable* parent);
        ScopeTable* getParentScope();
};

ScopeTable::ScopeTable(int total_buckets){
    this->total_buckets = total_buckets;
    parentScope = NULL;
    this->parent_id = "0";
    this->current_id = 1;
    this->deleted_id = 0;
    this->ptr = new SymbolInfo*[total_buckets];
    for(int i = 0; i < total_buckets; i++){
        this->ptr[i] = NULL;
    }
}

bool ScopeTable::insert(string name, string type){
    int count = 0;
    int hash_value = sdbmHash(name);
    int res = 0;

    if(ptr[hash_value] == NULL){
        ptr[hash_value] = new SymbolInfo(name, type);
        res = 1;
    }else{
        SymbolInfo* temp = ptr[hash_value];
        while(temp->next != NULL){
            if(temp->getName() == name){
                res = -1;
                break;
            }
            temp = temp->next;
            count++;
        }

        if(res == 0){
            if(temp->getName() == name){
                res = -1;
            }else{
                temp->next = new SymbolInfo(name, type);
                count++;
                res = 1;
            }
        }
    }

    string output = "";
    if(res == 1){
        cout << output << endl;
    }else{
        cout << output << endl;
    }

    fstream outputFile;
    outputFile.open("1805021_output.txt", ios::out | ios::app);
    outputFile << output << endl;
    outputFile.close();

    return res;
}

SymbolInfo* ScopeTable::lookup(string name){
    fstream outputFile;
    outputFile.open("1805021_output.txt", ios::out | ios::app);
    int hash_value = sdbmHash(name);
    SymbolInfo* res = NULL;
    string output = "";

    if(ptr[hash_value] == NULL){
        res = NULL;
    }
    else{
        int count = 0;
        int found = 0;
        SymbolInfo* temp = ptr[hash_value];
        while(temp->next != NULL){
            if(temp->getName() == name){
                res = temp;
                output = "Found in ScopeTable# " + getId() + " at position " + to_string(hash_value) + ", " + to_string(count);
                outputFile << output << endl;
                found = 1;
                break;
            }
            temp = temp->next;
            count++;
        }

        if((found==0) && temp->getName() == name){
            res = temp;
            output = "Found in ScopeTable# " + getId() + " at position " + to_string(hash_value) + ", " + to_string(count);
            outputFile << output << endl;
        }
    }

    outputFile.close();

    return res;
}

bool ScopeTable::deleteEntry(string name){
    bool res = false;
    int count = 0;
    int hash_value = sdbmHash(name);

    if(ptr[hash_value] == NULL) res = false;
    else{
        SymbolInfo* temp = ptr[hash_value];

        if(temp->getName() == name){
            ptr[hash_value] = temp->next;
            delete temp;
            res = true;
        }else{
            while(temp->next != NULL){
                if(temp->next->getName() == name){
                    SymbolInfo* temp2 = temp->next;
                    temp->next = temp->next->next;
                    delete temp2;
                    res = true;
                    count++;
                    break;
                }
                temp = temp->next;
            }
        }
    }

    string output = "";
    if(res){
        output = "Found in ScopeTable# " + getId() + " at position " + to_string(hash_value) + ", " + to_string(count) + "\n";
        output += "Deleted entry " + to_string(hash_value) + ", " + to_string(count) + " from current ScopeTable";
    }else{
        output = "Not found\n" + name + " not found";
    }

    fstream outputFile;
    outputFile.open("1805021_output.txt", ios::out | ios::app);
    outputFile << output << endl;
    outputFile.close();

    return res;
}

void ScopeTable::print(){
    fstream outputFile;
    outputFile.open("1805021_output.txt", ios::out | ios::app);

    outputFile << "Scope Table # " << getId() << endl;

    for(int i = 0; i < total_buckets; i++){
        if(ptr[i] != NULL){
            SymbolInfo* temp = ptr[i];
            cout << i << " --> ";
            outputFile << i << " --> ";
            while(temp != NULL){
                outputFile << "< " << temp->getName() << " : " << temp->getType() << " >  ";
                temp = temp->next;
            }
            outputFile << "\n";
        }else{
            outputFile << i << " -->\n";
        }
    }

    outputFile.close();
}

int ScopeTable::sdbmHash(string name){
    int hash = 0;
    for(int i = 0; i < name.length(); i++){
        hash = name[i] + (hash << 6) + (hash << 16) - hash;
    }
    return hash % total_buckets;
}

string ScopeTable::getId(){
    if(this->parent_id == "0") return to_string(this->current_id);
    else return this->parent_id + "." + to_string(this->current_id);
}

void ScopeTable::setDeletedId(int id){
    this->deleted_id = id;
}

int ScopeTable::getDeletedId(){
    return this->deleted_id;
}

void ScopeTable::setParentScope(ScopeTable* parent){
    this->parentScope = parent;
    this->parent_id = parent->getId();
    this->current_id += parent->deleted_id;
}

ScopeTable* ScopeTable::getParentScope(){
    return this->parentScope;
}

ScopeTable::~ScopeTable(){
    for(int i = 0; i < total_buckets; i++){
        if(ptr[i] != NULL){
            SymbolInfo* temp = ptr[i];
            while(temp != NULL){
                SymbolInfo* temp2 = temp;
                temp = temp->next;
                delete temp2;
            }
        }
    }

    delete[] ptr;

    this->parentScope = NULL;
}
