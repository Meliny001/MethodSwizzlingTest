//
//  UIViewController+Swizzling.m
//  MethodSwizzlingTest
//
//  Created by HYG_IOS on 2016/11/22.
//  Copyright © 2016年 magic. All rights reserved.
//

#import "UIViewController+Swizzling.h"
#import <objc/runtime.h>
#define ZGUserDefaults [NSUserDefaults standardUserDefaults]

static NSString * APP_LAST_VERSION = @"APP_LAST_VERSION";
@implementation UIViewController (Swizzling)
+ (void)load
{
    // 模拟更新提示
    NSString * currentVersion = [[NSBundle mainBundle]objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString * lastVersion = [ZGUserDefaults objectForKey:APP_LAST_VERSION];
    if ([currentVersion isEqualToString:lastVersion])return;
    
    [ZGUserDefaults setObject:currentVersion forKey:APP_LAST_VERSION];
    [ZGUserDefaults synchronize];
    
    // category实际不用加dispatch_once
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originalMethod = class_getInstanceMethod([self class], @selector(viewDidLoad));
        Method currentMethod = class_getInstanceMethod([self class], @selector(zgViewDidLoad));
        
        // 保证originalMethod只在父类实现
        BOOL addMethod = class_addMethod([self class], @selector(viewDidLoad), method_getImplementation(currentMethod), method_getTypeEncoding(currentMethod));
        
        if (addMethod)
        {
            // not exit(覆盖父类方法)
            class_replaceMethod([self class], @selector(zgViewDidLoad), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
            
        }else
        {
            // exit(交换实现)两个IMP先后均可
            method_exchangeImplementations(originalMethod, currentMethod);
            
        }
    });
    
}
// 保证originalMethod只在父类实现Debug调试打开查看
#if 0
- (void)viewDidLoad
{
    ZGLog(@"");//无打印信息(如果注释掉exit交换则走该实现)
}
#endif

- (void)zgViewDidLoad
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZGLog(@"appstore have new version now");
    });
    [self zgViewDidLoad];// 不会死循环将执行original
}
@end
