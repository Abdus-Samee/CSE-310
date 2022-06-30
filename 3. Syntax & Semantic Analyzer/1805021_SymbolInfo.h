#include <iostream>
#include <string>

using namespace std;

class SymbolInfo{
        string name;
        string type;
        string length;
    public:
        SymbolInfo* next;

        SymbolInfo(){
            next = NULL;
        }

        SymbolInfo(string name, string type){
            this->name = name;
            this->type = type;
            this->length = "";
            next = NULL;
        }

        ~SymbolInfo(){
            next = NULL;
        }
        
        string getName(){ return this->name; }
        string getType(){ return this->type; }
        void setName(string name){ this->name = name; }
        void setType(string type){ this->type = type; }
        void setArrayLength(string length){ this->length = length; }
};
