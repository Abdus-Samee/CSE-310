#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include "SymbolTable.h"

using namespace std;

vector<string> splitInput(string str){
    vector<string> ans;
    string delimiter = " ";
    size_t pos = 0;
    string token;
    while ((pos = str.find(delimiter)) != string::npos) {
        token = str.substr(0, pos);
        ans.push_back(token);
        str.erase(0, pos + delimiter.length());
    }

    return ans;
}

int main(){
    string str;
    ifstream input("input.txt");

    if(input.is_open()){
        while(input){
            getline(input, str);

            vector<string> res = splitInput(str);
            for(int i = 0; i < res.size(); i++){
                cout << res[i] << " ";
            }
            cout << endl;
        }
    }else cout << "Error opening file...";

    return 0;
}
