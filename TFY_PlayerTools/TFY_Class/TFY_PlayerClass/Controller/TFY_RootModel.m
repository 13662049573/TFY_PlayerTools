//
//  TFY_RootModel.m
//  TFY_CodeBuilder
//
//  Created by 田风有 on 2020/07/17.
//  Copyright © 2020 TFY_CodeBuilder. All rights reserved.
//

#import "TFY_RootModel.h"

@implementation PlayerCommand

-(void)setMaxtime:(NSString *)maxtime{
    _maxtime = maxtime;
}


-(RACCommand *)playerCommand{
    if (!_playerCommand) {
        _playerCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
            return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                
                [TFY_NetWorking getWithUrl:nil refreshCache:NO params:@{@"a":@"list",@"c":@"data",@"type":@(41)} success:^(id response) {
                    
                    TFY_RootModel *model = [TFY_RootModel tfy_ModelWithJson:response];
                    [subscriber sendNext:model];
                    [subscriber sendCompleted];
                    
                } fail:^(NSError *error) {
                    
                    [subscriber sendNext:@""];
                    [subscriber sendCompleted];
                    
                }];
                return nil;
            }];
        }];
    }
    return _playerCommand;
}

-(RACCommand *)maxtimehelpCommand{
    if (!_maxtimehelpCommand) {
        _maxtimehelpCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
            return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                
                [TFY_NetWorking getWithUrl:nil refreshCache:NO params:@{@"a":@"list",@"c":@"data",@"type":@(41),@"maxtime":self.maxtime} success:^(id response) {
                    
                    TFY_RootModel *model = [TFY_RootModel tfy_ModelWithJson:response];
                    [subscriber sendNext:model];
                    [subscriber sendCompleted];
                    
                } fail:^(NSError *error) {
                    
                    [subscriber sendNext:@""];
                    [subscriber sendCompleted];
                    
                }];
                return nil;
            }];
        }];
    }
    return _maxtimehelpCommand;
}



@end


@implementation TFY_RootModel

+(NSDictionary <NSString *, Class> *)tfy_ModelReplaceContainerElementClassMapper{
     return @{@"info" : TFY_InfoModel.class,
@"list" : TFY_ListModel.class,
     };
}

@end



@implementation TFY_InfoModel


@end



@implementation TFY_ListModel

+(NSDictionary <NSString *,NSString *> *)tfy_ModelReplacePropertyMapper{
   return @{@"item_Id" : @"id",
     };
}

@end


