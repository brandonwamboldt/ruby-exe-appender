#include "stdafx.h"
#include <iostream>
#include <fstream>
#include <iterator>
#include <vector>
#include <Windows.h>

using namespace std;

int main() {
    cout << "Hello World\n";

    int offset       = 0;
    int file_size    = 0;
    int payload_size = 0;
    wchar_t filename[MAX_PATH];

    // Get the path to myself
    GetModuleFileName(NULL, filename, MAX_PATH);
    wcout << "Reading self: " << filename << "\n";

    // Open self and find payload offset
    ifstream myfile;
    myfile.open(filename);
    myfile.seekg(-4, ios_base::end);
    myfile.read((char*)&offset, 4);

    // Calculate payload size and create a buffer to hold it
    file_size    = myfile.tellg();
    payload_size = file_size - offset - 4;
    char *buf = new char[payload_size + 1];

    cout << "File size: " << file_size << "\n";
    cout << "Read byte offset: " << offset << "\n";
    cout << "Payload Size: " << payload_size << "\n";

    // Read the payload
    myfile.seekg(offset);
    myfile.read(buf, payload_size);
    buf[payload_size] = '\0';
    myfile.close();

    myfile.close();
    cout << "Payload: '" << buf << "'\n";

    return 0;
}
