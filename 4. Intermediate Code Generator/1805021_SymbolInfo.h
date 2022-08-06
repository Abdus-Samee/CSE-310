#include <iostream>
#include <string>
#include <vector>

using namespace std;

class SymbolInfo{
        string name;
        string type;
        string length;
        string dataType;
        string functionReturnType;
        bool functionDefined;
        vector<string> params;
    public:
        SymbolInfo* next;
        string asmCode;
        string asmText;
        string offset;
        string tempVar;

        SymbolInfo(){
            next = NULL;
        }

        SymbolInfo(string name, string type){
            this->name = name;
            this->type = type;
            this->length = "";
            this->dataType = type;
            this->functionReturnType = "";
            this->functionDefined = false;
            this->asmCode = "";
            this->asmText = "";
            this->offset = 0;
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
        void setDataType(string data){ this->dataType = data; }
        void setFunctionDefined(bool d){ this->functionDefined = d; }
        void setFunctionReturnType(string rt){ this->functionReturnType = rt; }
        void setParams(vector<string> params){ this->params = params; }
        string getArrayLength() { return this->length; }
        string getDataType() { return this->dataType; }
        bool getFunctionDefined() { return this->functionDefined; }
        string getFunctionReturnType() { return this->functionReturnType; }
        vector<string> getParams() { return this->params; }
        void setAsmCode(string asmCode) { this->asmCode = asmCode; }
        string getAsmCode() { return this->asmCode; }
        void setAsmText(string asmText) { this->asmText = asmText; }
        string getAsmText() { return this->asmText; }
        void setOffset(string offset) { this->offset = offset; }
        string getOffset() { return this->offset; }
};
