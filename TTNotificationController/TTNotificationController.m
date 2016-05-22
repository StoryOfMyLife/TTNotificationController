//
//  TTNotificationController.m
//  TTNotificationController
//
//  Created by liuty on 16/5/22.
//  Copyright © 2016年 liuty. All rights reserved.
//

#import "TTNotificationController.h"
#import <objc/message.h>
#import <libkern/OSAtomic.h>

@interface _TTNotificationInfo : NSObject
{
    @public
    __weak TTNotificationController *_controller;
    __weak id _sender;
    NSString *_name;
    TTNotificationBlock _block;
}
@end

@implementation _TTNotificationInfo

- (NSUInteger)hash
{
    return [_name hash];
}

- (BOOL)isEqual:(id)object
{
    if (nil == object) {
        return NO;
    }
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    BOOL nameEqual = [_name isEqualToString:((_TTNotificationInfo *)object)->_name];
    BOOL senderEqual = YES;
    if (self->_sender || ((_TTNotificationInfo *)object)->_sender) {
        senderEqual = (self->_sender == ((_TTNotificationInfo *)object)->_sender);
    }
    return nameEqual && senderEqual;
}

- (NSString *)description
{
    NSMutableString *s = [NSMutableString stringWithFormat:@"<Name : %@", _name];
    [s appendFormat:@", Sender : %@", _sender];
    [s appendString:@">"];
    return s;
}

@end

@interface TTNotificationController ()

@end

@implementation TTNotificationController
{
    NSMapTable *_objectInfosMap;
    NSMutableSet *_infos;
    OSSpinLock _lock;
}

- (void)dealloc
{
    [self unobserveAll];
}

+ (instancetype)controller
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSPointerFunctionsOptions keyOptions = NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPointerPersonality;
        _objectInfosMap = [[NSMapTable alloc] initWithKeyOptions:keyOptions valueOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality capacity:0];
        _infos = [NSMutableSet set];
        _lock = OS_SPINLOCK_INIT;
    }
    return self;
}

- (void)observeName:(NSString *)aName block:(TTNotificationBlock)block
{
    [self observeName:aName object:nil block:block];
}

- (void)observeName:(NSString *)aName object:(id)sender block:(TTNotificationBlock)block
{
    NSAssert(0 != aName.length && NULL != block, @"Notification missing required parameters aName:%@ block:%p", aName, block);
    
    _TTNotificationInfo *_info = [[_TTNotificationInfo alloc] init];
    _info->_block = [block copy];
    _info->_name = [aName copy];
    _info->_controller = self;
    _info->_sender = sender;
    
    [self _observeInfo:_info];
}

- (void)_observeInfo:(_TTNotificationInfo *)info
{
    OSSpinLockLock(&_lock);
    id existInfo = [_infos member:info];
    OSSpinLockUnlock(&_lock);
    
    NSAssert(!existInfo, @"Notification already exists %@", existInfo);
    
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:info->_name object:info->_sender queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        info->_block(note);
    }];
    
    OSSpinLockLock(&_lock);
    [_objectInfosMap setObject:observer forKey:info];
    [_infos addObject:info];
    OSSpinLockUnlock(&_lock);
}

- (void)unobserveName:(NSString *)name
{
    [self unobserveName:name object:nil];
}

- (void)unobserveName:(NSString *)name object:(id)sender
{
    OSSpinLockLock(&_lock);
    _TTNotificationInfo *infoToRemove = nil;
    for (_TTNotificationInfo *info in _objectInfosMap) {
        if ([info->_name isEqualToString:name] && info->_sender == sender) {
            infoToRemove = info;
            break;
        }
    }
    if (infoToRemove) {
        id observerToRemove = [_objectInfosMap objectForKey:infoToRemove];
        [[NSNotificationCenter defaultCenter] removeObserver:observerToRemove];
        [_objectInfosMap removeObjectForKey:infoToRemove];
        [_infos removeObject:infoToRemove];
    }
    OSSpinLockUnlock(&_lock);
}

- (void)unobserveAll
{
    OSSpinLockLock(&_lock);
    NSMapTable *maps = [_objectInfosMap copy];
    [_objectInfosMap removeAllObjects];
    [_infos removeAllObjects];
    OSSpinLockUnlock(&_lock);
    
    for (id object in maps) {
        id observer = [maps objectForKey:object];
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
}

@end

static void *NSObjectTTNotificationControllerKey = &NSObjectTTNotificationControllerKey;

@implementation NSObject (TTNotificationController)

- (TTNotificationController *)notificationController
{
    id controller = objc_getAssociatedObject(self, NSObjectTTNotificationControllerKey);
    
    if (nil == controller) {
        controller = [TTNotificationController controller];
        self.notificationController = controller;
    }
    return controller;
}

- (void)setNotificationController:(TTNotificationController *)notificationController
{
    objc_setAssociatedObject(self, NSObjectTTNotificationControllerKey, notificationController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
