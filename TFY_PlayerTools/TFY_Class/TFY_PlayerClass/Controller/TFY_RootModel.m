//
//  TFY_RootModel.m
//  TFY_CodeBuilder
//
//  Created by 田风有 on 2020/07/17.
//  Copyright © 2020 TFY_CodeBuilder. All rights reserved.
//

#import "TFY_RootModel.h"

@implementation PlayerCommand

-(RACCommand *)playerCommand{
    if (!_playerCommand) {
        _playerCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
            return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
                TFY_RootModel *models = [TFY_RootModel tfy_ModelobjectArrayWithFilename:@"Playerdata.json"];
                [subscriber sendNext:models];
                [subscriber sendCompleted];
                return nil;
            }];
        }];
    }
    return _playerCommand;
}

@end


@implementation TFY_RootModel

+(NSDictionary <NSString *, Class> *)tfy_ModelReplaceContainerElementClassMapper{
     return @{@"list" : TFY_ListModel.class,
@"page" : TFY_PageModel.class,
     };
}

@end

@implementation TFY_ListModel

@end

@implementation TFY_PageModel

@end

