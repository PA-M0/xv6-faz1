#include "user.h"
#include "kernel/types.h"
#include "kernel/stst.h"


int main (){
    struct syshistory *history = malloc(sizeof(struct syshistory));
    int error =  syshistory(history);
    if (error != 0){
        return -1
    }



    printf("XOXOXOXOXOXOXOXOXXOXOXOXOXOXOXOXOXOXOXOXOXOXOOX");
    retern 0;

}