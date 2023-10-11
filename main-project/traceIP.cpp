#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string>
using namespace std;

string runCommand(const char*);

int main() {

    string command; 
    command = "whois 52.162.82.248 | grep -oP '^Country:        \\K.*'";
    cout << runCommand(command);
    return 0;
}

string runCommand(const char* command) {
    string output;
    
    // Open a pipe to the command's standard output
    FILE* pipe = popen(command, "r");
    if (!pipe) {
        perror("popen");
    }

    // Read the command's output
    char buffer[128];
    while (!feof(pipe)) {
        if (fgets(buffer, 128, pipe) != NULL) {
            output=buffer;
        }
    }

    // Close the pipe
    pclose(pipe);
    
    return output;
}
