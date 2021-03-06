//
//  ServerThread.m
//  TCPDataTransfer
//
//  Created by 仝兴伟 on 2018/5/26.
//  Copyright © 2018年 TW. All rights reserved.
//  https://www.youtube.com/watch?v=pDK3zFQqc5E&list=PLtBSL3_Le8pNkcH4TjkrAdppQGaBMmQSM
//  列表
//  https://www.youtube.com/watch?v=lPD5TY9D-Ig
//  整合

#import "ServerThread.h"
#import "ClientThread.h"

@implementation ServerThread

- (void)initializeServer:(NSTextField *)target_text_field {
    
    tx_recv = target_text_field;
    
    CFSocketContext sctx = {0,(__bridge void *)(self),NULL,NULL,NULL};
    
    obj_server = CFSocketCreate(kCFAllocatorDefault, // 为对象分配内存 可为nil
                                AF_INET, // 协议族 0或负数  默认为 PF_INET
                                SOCK_STREAM, // 套接字类型，协议族为 PF_INET 默认
                                IPPROTO_TCP, // 套接字协议
                                kCFSocketAcceptCallBack, // 触发回调消息类型
                                TCPServerCallBackHandler, // 回调函数
                                &sctx); // 一个持有CFSocket结构消息的对象， 可以为nil
    
    int so_reuse_flag = 1;
    setsockopt(CFSocketGetNative(obj_server),
               SOL_SOCKET,SO_REUSEADDR, // 运行本地地址重用
               &so_reuse_flag,
               sizeof(so_reuse_flag));
    
    setsockopt(CFSocketGetNative(obj_server),
               SOL_SOCKET,SO_REUSEPORT,  // 运行本地地址&端口重用
               &so_reuse_flag,
               sizeof(so_reuse_flag));
    
    struct sockaddr_in sock_addr;
    memset(&sock_addr, 0, sizeof(sock_addr));
    sock_addr.sin_len = sizeof(sock_addr);
    sock_addr.sin_family = AF_INET;
    sock_addr.sin_port = htons(6658); // 监听端口
    sock_addr.sin_addr.s_addr = INADDR_ANY;
    
    CFDataRef dref = CFDataCreate(kCFAllocatorDefault, (UInt8*)&sock_addr, sizeof(sock_addr));
    CFSocketSetAddress(obj_server, dref);
    CFRelease(dref);
}


/**
 main
 */
- (void)main {
    CFRunLoopSourceRef loopref = CFSocketCreateRunLoopSource(kCFAllocatorDefault, obj_server, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), loopref, kCFRunLoopDefaultMode);
    CFRelease(loopref);
    CFRunLoopRun();
}


/**
 StopServer
 */
- (void)StopServer {
    CFSocketInvalidate(obj_server);
    CFRelease(obj_server);
    CFRunLoopStop(CFRunLoopGetCurrent());
}


void TCPServerCallBackHandler(CFSocketRef s, CFSocketCallBackType callbacktype, CFDataRef address, const void *data, void *info) {
    switch (callbacktype) {
        case kCFSocketAcceptCallBack:
        {
            ServerThread *obj_server_ptr = (__bridge ServerThread*)info;
            // 客户端开始接受
            ClientThread *obj_accepted_socket = [[ClientThread alloc]init];
            [obj_accepted_socket initizeNative:*(CFSocketNativeHandle*)data showRecData:obj_server_ptr->tx_recv];
            [obj_accepted_socket start];
        }
            break;
            
        default:
            break;
    }
}


@end
