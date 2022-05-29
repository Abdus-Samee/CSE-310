#include <iostream>
#include <string>

using namespace std;

class SymbolInfo{
        string name;
        string type;
    public:
        SymbolInfo* next;
        SymbolInfo();
        ~SymbolInfo();
        SymbolInfo(string name, string type);
        string getName(){ return this->name; }
        string getType(){ return this->type; }
        void setName(string name){ this->name = name; }
        void setType(string type){ this->type = type; }
};

SymbolInfo::SymbolInfo(){}

SymbolInfo::SymbolInfo(string name, string type){
    this->name = name;
    this->type = type;
    next = NULL;
}

SymbolInfo::SymbolInfo(string name, string type){
    this->name = name;
    this->type = type;
    next = NULL;
}
