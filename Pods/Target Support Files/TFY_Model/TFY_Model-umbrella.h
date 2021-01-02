#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NSObject+TFY_Model.h"
#import "TFY_ModelKit.h"
#import "TFY_ModelSqlite.h"

FOUNDATION_EXPORT double TFY_ModelVersionNumber;
FOUNDATION_EXPORT const unsigned char TFY_ModelVersionString[];

