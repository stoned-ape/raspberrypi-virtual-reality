#include <sys/socket.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <errno.h>
#include <unistd.h>
#include <MPU6050.h>


int ret;

#define SYSCALL(call) \
ret=call; \
if(ret==-1){ \
   	printf("syscall error: (%s) in function %s at line %d of file %s\n", \
	strerror(errno),__func__,__LINE__,__FILE__); \
	exit(errno); \
}





MPU6050 device(0x68);

int main() {
	float data[6];

	sleep(1); 
	float offset[6]={0,0,0,0,0,0};

    int er=0;
    int fd=SYSCALL(socket(AF_INET,SOCK_STREAM,0));
    struct sockaddr_in sa;
    memset(&sa,0,sizeof sa);
    sa.sin_family = AF_INET;
    sa.sin_addr.s_addr = INADDR_ANY;
    sa.sin_port = htons(8080);
    SYSCALL(bind(fd,(struct sockaddr*)&sa,sizeof(sa)));
    SYSCALL(listen(fd,100));
    unsigned int len;
    printf("accepting \n");
    int nfd=SYSCALL(accept(fd,(struct sockaddr*)&sa,&len));
    printf("accepted \n");
    char buf[1024];
    while(1){
        int n=SYSCALL(read(nfd,buf,1024));
		device.getAccel(data+0,data+1,data+2);
		device.getGyro( data+3,data+4,data+5);
		for(int i=0;i<6;i++) data[i]-=offset[i];
        SYSCALL(send(nfd,data,6*sizeof(float),0));
    }
}


