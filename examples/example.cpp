#include "stdafx.h"
#include <iostream>
#include <fstream>
#include <iterator>
#include <vector>

using namespace std;

int main() {
    cout << "Hello World\n";

    int offset       = 0;
    int file_size    = 0;
    int payload_size = 0;

    ifstream myfile;
    myfile.open("ConsoleApplication.exe");
    myfile.seekg(-4, ios_base::end);
    myfile.read((char*)&offset, 4);
    file_size    = myfile.tellg();
    payload_size = file_size - offset - 4;
    char *buf = new char[payload_size + 1];

    cout << "File size: " << file_size << "\n";
    cout << "Read byte offset: " << offset << "\n";
    cout << "Payload Size: " << payload_size << "\n";

    myfile.seekg(offset);
    myfile.read(buf, payload_size);
    buf[payload_size] = '\0';

    cout << "Payload: '" << buf << "'\n";

    myfile.close();
    cout << "Done\n";

    return 0;
}
