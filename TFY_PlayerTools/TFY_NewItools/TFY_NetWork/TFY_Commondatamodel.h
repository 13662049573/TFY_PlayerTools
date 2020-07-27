//
//  TFY_Commondatamodel.h
//  Femalepregnancy
//
//  Created by tiandengyou on 2019/12/11.
//  Copyright © 2019 田风有. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TFY_Commondatamodel : NSObject
/**手机号*/
@property(nonatomic , copy)NSString *phone_str;
/**验证码*/
@property(nonatomic , copy)NSString *code_str;
/**验证码不同类型*/
@property(nonatomic , copy)NSString *type_str;
/**token失效来判断是否更新token值 2 失效更新*/
@property(nonatomic , assign)NSInteger token_count;
/**用户openid*/
@property(nonatomic , copy)NSString *openid;
/**accessToken*/
@property(nonatomic , copy)NSString *accessToken;
/**refreshToken*/
@property(nonatomic , copy)NSString *refreshToken;
/**生日 类型:string 格式:2019-11-11*/
@property(nonatomic , copy)NSString *birthday_str;
/**身高 类型:int*/
@property(nonatomic , assign)NSInteger height_int;
/**经期长度 类型:int*/
@property(nonatomic , assign)NSInteger lunationLength_int;
/**最后一次经期开始日 类型:string 格式:2019-11-11*/
@property(nonatomic , copy)NSString *lunationTime_str;
/**周期长度 类型:int*/
@property(nonatomic , assign)NSInteger periodLength_int;
/**体重 类型:string*/
@property(nonatomic , copy)NSString *weight_str;
/**用户协议和说明类型唯一标识(USER_AGREEMENT用户协议、USE_EXPLAIN使用说明) 类型:string*/
@property(nonatomic , copy)NSString *uniqueType_str;
/**反馈内容*/
@property(nonatomic , copy)NSString *content_str;
/**日历上用户选择的日期*/
@property(nonatomic , copy)NSString *recordTime_str;
/**温度数据*/
@property(nonatomic , copy)NSString *temperatureData_str;
/**是否爱爱 0为否、1为是*/
@property(nonatomic , assign)NSInteger loveStatus_int;
/**mac地址 */
@property(nonatomic , copy)NSString *macAddress_str;
/**绑定id */
@property(nonatomic , assign)NSInteger id_int;
@property(nonatomic , copy)NSString *ids_str;
/**日历开始日期 */
@property(nonatomic , copy)NSString *calendarStart_str;
/**日历结束日期 */
@property(nonatomic , copy)NSString *calendarEnd_str;
/**分页  */
@property(nonatomic , assign)NSInteger pageNum_int;
/**分页个数 */
@property(nonatomic , assign)NSInteger pageSize_int;
/**版本号 */
@property(nonatomic , copy)NSString *version_str;
/**日期 格式为2020-03-08 类型:string*/
@property(nonatomic , copy)NSString *dayDate_str;
/**时间 格式为08:45 类型:string*/
@property(nonatomic , copy)NSString *minuDate_str;
@property(nonatomic , assign)NSInteger labelTypeCode_int;
@property(nonatomic , copy)NSString *date_str;
@end

@interface DataModel :NSObject
@property (nonatomic , assign) NSInteger             returnCode;
@property (nonatomic , copy) NSString              * returnMsg;
@property (nonatomic , copy) NSString              * sysdate;
@property (nonatomic , assign) BOOL              data;
@end


NS_ASSUME_NONNULL_END
