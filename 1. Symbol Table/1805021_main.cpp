#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include "1805021_SymbolTable.h"

using namespace std;

vector<string> splitInput(string str){
    vector<string> ans;
    char* token = strtok((char*)str.c_str(), " ");
    while(token){
        ans.push_back(token);
        token = strtok(NULL, " ");
    }

    return ans;
}

int main(){
    int c = 0;
    string str;
    ifstream input("1805021_input.txt");
    SymbolTable symbolTable;

    if(input.is_open()){
        while(input){
            if(getline(input, str)){
                if(c == 0){
                    int bucket_no = stoi(str);
                    cout << bucket_no << endl;
                    symbolTable = SymbolTable(bucket_no);
                    c++;
                }else{
                    fstream outputFile;
                    outputFile.open("1805021_output.txt", ios::out | ios::app);
                    outputFile << str << endl;
                    outputFile.close();

                    vector<string> res = splitInput(str);

                    if(res[0] == "I"){
                        string name = res[1];
                        string type = res[2];
                        symbolTable.insert(name, type);
                    }else if(res[0] == "L"){
                        string name = res[1];
                        SymbolInfo* info = symbolTable.lookup(name);
                    }else if(res[0] == "D"){
                        string name = res[1];
                        symbolTable.remove(name);
                    }else if(res[0] == "P"){
                        if(res[1] == "A") symbolTable.printAllScopeTables();
                        else if(res[1] == "C") symbolTable.printCurrentScopeTable();
                        else cout << "Incorrect format of input" << endl;
                    }else if(res[0] == "S"){
                        symbolTable.enterScope();
                    }else if(res[0] == "E"){
                        symbolTable.exitScope();
                    }else cout << "Incorrect format of input..." << endl;

                    c++;
                }
            }
        }
    }else cout << "Error opening file...";

    return 0;
}
