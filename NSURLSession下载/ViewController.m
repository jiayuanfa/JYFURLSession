//
//  ViewController.m
//  NSURLSession下载
//
//  Created by mac on 2017/2/20.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "ViewController.h"
#import "JYFProgressButton.h"

@interface ViewController ()<NSURLSessionDownloadDelegate>

// 管理全局的session任务
@property (nonatomic, strong) NSURLSession *session;

@property (weak, nonatomic) IBOutlet JYFProgressButton *progressView;

/**
 全局的下载任务
 */
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

/**
 暂停的时候已经下载的数据
 */
@property (nonatomic, strong) NSData *resumeData;

/**
 上次刷新的数值
 */
@property (nonatomic, assign) float lastUpdateProgressValue;

@end

@implementation ViewController

- (NSURLSession *)session{
    if (!_session) {
        // config 提供了一个全局的网络环境配置 包括身份验证 浏览器类型 cookie 缓存 超时
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        // 设置代理的队列
        /*
         队列：设置回调的代理方法在哪里执行 这里只是应用于回调 那么下载一定是在异步执行的
             - 代理的队列 如果给 nil 在多个线程中执行时没有问题的
             - [NSOperationQueue mainQueue] 主队列 可以给nil 默认子线程
         Session 会对代理强引用 如果任务结束后 不取消Session 会出现内存泄露
         // 真正的网络访问
         - 在网络开发中，应该将所有的网络访问操作，封装到一个方法中，由一个统一的单例对象负责所有的网络事件
         - Session对代理（单例）进行强引用！单例本身就是一个静态的实例，本身不需要释放
         - AFN -> 需要建立一个AFN 的Manager
         */
        
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -- NSURLSession Delegate
#pragma mark -- 下载完成 7.0以下三个方法  都要实现，但是8.0就不需要了 只需要实现下载完成就好了
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    // 任务完成
    [self.session finishTasksAndInvalidate]; // 只是内部干掉了代理 并没有清空
    // 清空我们的Session 为了让它下载懒加载的时候重新初始化
    self.session = nil;
    NSLog(@"%@",location);
}

#pragma mark -- 下载续传
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
    
}

#pragma mark -- 下载进度监听的方法
/*
 1.session
 2.downloadTask 调用代理方式的下载任务
 3.bytesWritten 本次下载的字节数
 4.totalBytesWritten 已经下载的字节数
 5.totalBytesExpectedToWrite 期望下载的总大小
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    // 下载进度
    float progress = (float) totalBytesWritten / totalBytesExpectedToWrite;
    NSLog(@"%f",progress);
    
    // 打印当前线程
    NSLog(@"%f %@",progress,[NSThread currentThread]);
    
    // 回到主线程更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = progress;
    });
}

#pragma mark -- 开始下载
- (IBAction)start:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString:@"http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.4.1.dmg"];
    // 使用下载方法下载
    // 如果需要下载进度，也需要通过监听 NSURLSession和NSURLConnection一样都是通过代理！！
    // NSURLSession 它的全局的 Session 单例是整个系统的
    // NSURLSession是全局的单例 是整个系统的 那么我们设置代理不能全局设置
    /*
     如果需要跟进下载进度，不能使用快代码回调的方式
     如果使用Block 默认是子线程
     所以 要回到主线程
     */
    //    [[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    //        NSLog(@"%@",location);
    //    }];
    // 需要使用代理的方式
//    [[self.session downloadTaskWithURL:url] resume];
    
    // 断点续传 需要使用全局的downloadTask 下载
    self.resumeData = nil;
    [self.downloadTask cancel];
    self.downloadTask = [self.session downloadTaskWithURL:url];
    // 开始任务
    [self.downloadTask resume];
}

#pragma mark -- 暂停下载
- (IBAction)pause:(UIButton *)sender {
    
    // 暂停 肯定是暂停任务
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        // resumeData : 续传的数据（下载了多少）
        NSLog(@"数据的长度：%tu",resumeData.length);
        
        self.resumeData = resumeData;
        // 释放下载任务 我们task设置为weak 就可以不用释放了 因为我们的任务都是由Session发起的 而Session对发起的任务都会持有一个Strong 都会持有一个强引用 如果不手动释放 非常危险
        // 解决Session强引用的问题 就必须让Session释放掉
        self.downloadTask = nil;
    }];
}

#pragma mark -- 继续下载
- (IBAction)resume:(UIButton *)sender {
    
    NSLog(@"%ld",(long)self.downloadTask.state);
    if (self.resumeData == nil) {
        return;
    }
    // 继续下载 继续下载任务 也是应该由Session发起的
    // 使用续传数据启动下载任务
    self.downloadTask = [self.session downloadTaskWithResumeData:self.resumeData];
    // 清空续传数据
    self.resumeData = nil;
    // 所有的任务都是默认挂起的
    [self.downloadTask resume];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    // 取消会话
    [self.session invalidateAndCancel];
    self.session = nil;
}

@end
