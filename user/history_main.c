
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"

int main (int argc, char *argv[]){
    history(atoi(argv[1]));
    return 0;
}