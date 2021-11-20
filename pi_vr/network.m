//
//  network.m
//  pi_vr
//
//  Created by Apple1 on 11/14/21.
//

#import <Foundation/Foundation.h>
#import "pi_vr-Bridging-Header.h"
#import <pthread.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <assert.h>
#import <errno.h>
#import <unistd.h>
#import <arpa/inet.h>
#import <sys/time.h>
#import <stdbool.h>


int ret;

#define SYSCALL(call) \
ret=call; \
if(ret==-1){ \
    printf("syscall error: (%s) in function %s at line %d of file %s\n", \
        strerror(errno),__func__,__LINE__,__FILE__); \
    exit(errno); \
}

#define PTHREAD(call) \
ret=call; \
if(ret!=0){ \
    printf("pthread error: (%s) in function %s at line %d of file %s\n", \
        strerror(ret),__func__,__LINE__,__FILE__); \
    exit(ret); \
}


simd_float3 pi_acc;
simd_float3 pi_gyro;
float timer;
float pi_dt;
float PI=3.1415926535;
pthread_cond_t cond;
pthread_t t;
pthread_mutex_t mutex;

void *pointer(void *v){return v;}


float itime(){
    struct timeval tp;
    SYSCALL(gettimeofday(&tp,NULL));
    return (tp.tv_sec%(60*60*24))+tp.tv_usec/1E6;
}



void *thread_func(void *v){
    int fd=SYSCALL(socket(AF_INET,SOCK_STREAM,0));
    struct sockaddr_in sa;
    memset(&sa,0,sizeof sa);
    sa.sin_family = AF_INET;
    sa.sin_addr.s_addr = inet_addr("169.254.2.194");
    sa.sin_port = htons(8080);
    printf("connecting \n");
    printf("%d\n",fd);
    SYSCALL(connect(fd,(struct sockaddr*)&sa,sizeof(sa)));
    printf("connected \n");
    float data[6];
    float prev=itime();
    bool started=false;
    while(1){
        SYSCALL(write(fd,"bruh\n",(ssize_t)5));
        SYSCALL(read(fd,data,(ssize_t)6*sizeof(float)));
        int xpi=0,ypi=1,zpi=2;
        pi_acc.z=+data[xpi];
        pi_acc.x=-data[ypi];
        pi_acc.y=-data[zpi];
        pi_gyro.z=+(data[3+xpi]*PI/180.0-0.006126106);
        pi_gyro.x=-(data[3+ypi]*PI/180.0+0.01558579);
        pi_gyro.y=-(data[3+zpi]*PI/180.0-0.013316863);
        
        SYSCALL(usleep((useconds_t)10000));
        pi_dt=itime()-prev;
        prev=itime();
        if(!started){
            PTHREAD(pthread_cond_signal(&cond));
            started=true;
        }
    }

    
    
    return NULL;
}

void client(){
    PTHREAD(pthread_mutex_init(&mutex,NULL));
    PTHREAD(pthread_cond_init(&cond,NULL));
    PTHREAD(pthread_create(&t,NULL,&thread_func,NULL));
    PTHREAD(pthread_cond_wait(&cond,&mutex));
}
