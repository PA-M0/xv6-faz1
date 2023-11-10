#define MAX_HISTORY 16
#define INPUT_BUF_SIZE 128

struct historyBufferArray{
    char bufferArr[MAX_HISTORY][INPUT_BUF_SIZE];
    uint lengthsArr[MAX_HISTORY];
    uint lastCommandIndex;
    int numOfCommandsInMem;
    int currentHistory;
    char current_cm [128];//current command
    int id;
};

extern struct historyBufferArray historyBuf;
