// ============================================================
//  CoreCrack.js — 巨魔Core-SET「一键三连」运行时破解 (frida)
//
//  三连：
//    1. hasLocalActivationCard  -> 永远返回 true（本地激活卡判定）
//    2. createOrRefreshSessionWithCard:completion: -> 伪造成功 token（绕过服务端 order.klpjwycb.xyz）
//    3. finishActivationWithCard:... -> 强制成功分支（忽略 DEVICE_CARD_MISMATCH / LOCAL_CARD_REQUIRED）
//
//  环境：TrollStore（巨魔）设备 + Frida
//  用法：frida -U -f com.apple.manager -l CoreCrack.js --no-pause
//        （Bundle ID 是 com.apple.manager，见 Info.plist）
//
//  注意：所有 hook 均针对目标 App 自身的方法，仅在你自己的设备/程序上做研究测试。
// ============================================================

'use strict';

// —— 工具：安全获取 ObjC 类/方法，不存在则返回 null ——
function tryHook(className, selName, replacement) {
    try {
        var cls = ObjC.classes[className];
        if (!cls) {
            console.log('[CoreCrack] 类不存在: ' + className);
            return false;
        }
        var sel = selName;
        var method = cls[sel];
        if (!method) {
            console.log('[CoreCrack] 方法不存在: ' + className + ' ' + selName);
            return false;
        }
        // Interceptor.replace / ObjC 方式
        var impl = method.implementation;
        Interceptor.replace(impl, replacement);
        console.log('[CoreCrack] ✅ 已 hook: ' + className + ' ' + selName);
        return true;
    } catch (e) {
        console.log('[CoreCrack] ❌ hook 失败: ' + className + ' ' + selName + ' -> ' + e);
        return false;
    }
}

// —— 三连 hook ——

// 1. hasLocalActivationCard -> 返回 true
//    BOOL 返回用 x0 (w0)，1 = YES
function hook1() {
    var clsName = 'PPMTActivationService';
    var cls = ObjC.classes[clsName];
    if (!cls) {
        // 也可能挂在 PPMTRewardsAPI 上（逆向发现 hasLocalActivationCard 在 RewardsAPI 附近）
        clsName = 'PPMTRewardsAPI';
        cls = ObjC.classes[clsName];
    }
    if (!cls) {
        console.log('[CoreCrack] ⚠️ 未找到 hasLocalActivationCard 所在类');
        return;
    }
    var sel = 'hasLocalActivationCard';
    var m = cls[sel];
    if (!m) {
        console.log('[CoreCrack] ⚠️ 未找到 ' + sel);
        return;
    }
    var impl = m.implementation;
    Interceptor.replace(impl, new NativeCallback(function (self, _cmd) {
        console.log('[CoreCrack] hasLocalActivationCard -> 强制返回 YES');
        return 0x1; // BOOL YES
    }, 'bool', ['pointer', 'pointer']));
    console.log('[CoreCrack] ✅ [1/3] hasLocalActivationCard 已 hook');
}

// 2. createOrRefreshSessionWithCard:completion: -> 伪造成功，直接回调
//    签名: (void)createOrRefreshSessionWithCard:(id)card completion:(void(^)(NSString *token, NSError *err))completion
function hook2() {
    var clsName = 'PPMTRewardsAPI';
    var cls = ObjC.classes[clsName];
    if (!cls) {
        clsName = 'PPMTActivationService';
        cls = ObjC.classes[clsName];
    }
    if (!cls) { console.log('[CoreCrack] ⚠️ 未找到类'); return; }
    var sel = 'createOrRefreshSessionWithCard:completion:';
    var m = cls[sel];
    if (!m) { console.log('[CoreCrack] ⚠️ 未找到 ' + sel); return; }
    var orig = m.implementation;
    Interceptor.replace(orig, new NativeCallback(function (self, _cmd, card, completion) {
        console.log('[CoreCrack] [2/3] 伪造会话成功 token（跳过 order.klpjwycb.xyz）');
        var comp = new ObjC.Block(completion);
        var fakeToken = ObjC.classes.NSString.stringWithString_('FAKE_TOKEN_CRACKED');
        comp(fakeToken, null); // 成功回调
    }, 'void', ['pointer', 'pointer', 'pointer', 'pointer']));
    console.log('[CoreCrack] ✅ [2/3] createOrRefreshSession 已 hook');
}

// 3. finishActivationWithCard:pending:progress:completion: -> 强制成功
function hook3() {
    var clsName = 'PPMTActivationService';
    var cls = ObjC.classes[clsName];
    if (!cls) { console.log('[CoreCrack] ⚠️ 未找到 PPMTActivationService'); return; }
    var sel = 'finishActivationWithCard:pending:progress:completion:';
    var m = cls[sel];
    if (!m) { console.log('[CoreCrack] ⚠️ 未找到 ' + sel); return; }
    var orig = m.implementation;
    Interceptor.replace(orig, new NativeCallback(function (self, _cmd, card, pending, progress, completion) {
        console.log('[CoreCrack] [3/3] 强制激活成功（忽略 DEVICE_CARD_MISMATCH/LOCAL_CARD_REQUIRED）');
        var comp = new ObjC.Block(completion);
        comp(0x1, null); // success = YES
    }, 'void', ['pointer', 'pointer', 'pointer', 'pointer', 'pointer', 'pointer']));
    console.log('[CoreCrack] ✅ [3/3] finishActivation 已 hook');
}

// 主流程
function main() {
    console.log('============================================');
    console.log(' CoreCrack — 巨魔Core-SET 一键三连破解');
    console.log('============================================');
    hook1();
    hook2();
    hook3();
    console.log('============================================');
    console.log(' 三连 hook 完成，激活流程已被绕过。');
    console.log('============================================');
}

// 等待 ObjC runtime 加载
if (ObjC.available) {
    main();
} else {
    console.log('[CoreCrack] 等待 ObjC runtime ...');
    var t = setInterval(function () {
        if (ObjC.available) { clearInterval(t); main(); }
    }, 100);
}