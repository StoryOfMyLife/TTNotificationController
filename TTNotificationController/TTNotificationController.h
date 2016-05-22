//
//  TTNotificationController.h
//  TTNotificationController
//
//  Created by liuty on 16/5/22.
//  Copyright © 2016年 liuty. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^TTNotificationBlock)(NSNotification *noti);

@interface TTNotificationController : NSObject

+ (instancetype)controller;

- (void)observeName:(NSString *)aName block:(TTNotificationBlock)block;

- (void)observeName:(NSString *)aName object:(id)sender block:(TTNotificationBlock)block;

- (void)unobserveName:(NSString *)name;

- (void)unobserveName:(NSString *)name object:(id)sender;

- (void)unobserveAll;

@end

@interface NSObject (TTNotificationController)

@property (nonatomic, strong) TTNotificationController *notificationController;

@end
