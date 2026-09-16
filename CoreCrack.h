// ============================================================
//  CoreCrack.h — 巨魔Core-SET 一键三连破解（手机端）
//
//  三刀：
//    1. hasLocalActivationCard -> 永远 YES（本地激活卡）
//    2. createOrRefreshSessionWithCard:completion: -> 跳过服务端
//    3. finishActivationWithCard:... -> 强制成功（绕过设备绑定错误码）
//
//  环境：TrollStore（巨魔）侧载运行。
// ============================================================

#import <Foundation/Foundation.h>

@interface CoreCrack : NSObject

// 定位 Core 二进制
+ (NSString *)locateCoreBinary;

// 三连 patch（返回每刀的成败）
+ (NSDictionary *)crackAllAtPath:(NSString *)binPath error:(NSError **)error;

// 单刀：patch hasLocalActivationCard 返回 YES
+ (BOOL)patchHasLocalActivationCardAtPath:(NSString *)binPath error:(NSError **)error;

// 单刀：让 createOrRefreshSessionWithCard 返回成功（由运行时完成，静态方案为 stub 替换）
+ (BOOL)patchSessionCreationAtPath:(NSString *)binPath error:(NSError **)error;

// 单刀：让 finishActivation 永久成功
+ (BOOL)patchFinishActivationAtPath:(NSString *)binPath error:(NSError **)error;

// 重签名（ldid）
+ (BOOL)resignBinaryAtPath:(NSString *)binPath error:(NSError **)error;

@end