// ============================================================
//  main.m — CoreCrack 三连破解工具入口
//
//  两个按钮：
//    [一键三连-静态]  静态 patch hasLocalActivationCard + ldid 重签名
//    [运行时 Hook]    在注入场景下替换三方法 IMP（配合 dylib/frida）
// ============================================================

#import <UIKit/UIKit.h>
#import "CoreCrack.h"

@interface CrackVC : UIViewController
@end

@implementation CrackVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1.0];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"CoreCrack — 一键三连";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textAlignment = NSTextAlignmentCenter;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:title];

    UILabel *binLabel = [[UILabel alloc] init];
    binLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    binLabel.font = [UIFont systemFontOfSize:12];
    binLabel.numberOfLines = 0;
    binLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:binLabel];

    UIButton *btnStatic = [UIButton buttonWithType:UIButtonTypeSystem];
    [btnStatic setTitle:@"① 静态三连（patch + 重签）" forState:UIControlStateNormal];
    [btnStatic setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnStatic.backgroundColor = [UIColor colorWithRed:0.9 green:0.25 blue:0.2 alpha:1.0];
    btnStatic.layer.cornerRadius = 10;
    btnStatic.translatesAutoresizingMaskIntoConstraints = NO;
    [btnStatic addTarget:self action:@selector(doStatic) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnStatic];

    UIButton *btnRuntime = [UIButton buttonWithType:UIButtonTypeSystem];
    [btnRuntime setTitle:@"② 运行时三连 Hook" forState:UIControlStateNormal];
    [btnRuntime setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnRuntime.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1.0];
    btnRuntime.layer.cornerRadius = 10;
    btnRuntime.translatesAutoresizingMaskIntoConstraints = NO;
    [btnRuntime addTarget:self action:@selector(doRuntime) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnRuntime];

    UITextView *log = [[UITextView alloc] init];
    log.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    log.textColor = [UIColor colorWithRed:0.7 green:1.0 blue:0.7 alpha:1.0];
    log.font = [UIFont fontWithName:@"Menlo" size:12] ?: [UIFont systemFontOfSize:12];
    log.editable = NO;
    log.tag = 999;
    log.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:log];

    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [title.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [title.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [binLabel.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
        [binLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [binLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [btnStatic.topAnchor constraintEqualToAnchor:binLabel.bottomAnchor constant:16],
        [btnStatic.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [btnStatic.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [btnStatic.heightAnchor constraintEqualToConstant:52],
        [btnRuntime.topAnchor constraintEqualToAnchor:btnStatic.bottomAnchor constant:10],
        [btnRuntime.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [btnRuntime.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [btnRuntime.heightAnchor constraintEqualToConstant:52],
        [log.topAnchor constraintEqualToAnchor:btnRuntime.bottomAnchor constant:12],
        [log.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [log.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [log.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-12],
    ]];

    NSString *bin = [CoreCrack locateCoreBinary];
    binLabel.text = bin ? [NSString stringWithFormat:@"目标：%@", bin]
                        : @"⚠️ 未定位到 Core（确认已装 Core.app）";
}

- (void)log:(NSString *)m {
    UITextView *tv = [self.view viewWithTag:999];
    tv.text = [NSString stringWithFormat:@"%@%@\n", tv.text ?: @"", m];
    if (tv.contentSize.height > tv.bounds.size.height)
        [tv scrollRangeToVisible:NSMakeRange(tv.text.length - 1, 1)];
}

- (void)doStatic {
    NSString *bin = [CoreCrack locateCoreBinary];
    if (!bin) { [self log:@"❌ 未定位 Core"]; return; }
    NSError *err = nil;
    [self log:@"[①静态] patch hasLocalActivationCard ..."];
    BOOL ok = [CoreCrack patchHasLocalActivationCardAtPath:bin error:&err];
    if (!ok) { [self log:[NSString stringWithFormat:@"❌ %@", err.localizedDescription]]; return; }
    [self log:@"  ✅ 第一刀完成（本地激活卡 → 永远 YES）"];
    [self log:@"[①静态] ldid 重签名 ..."];
    if ([CoreCrack resignBinaryAtPath:bin error:&err]) {
        [self log:@"  ✅ 重签名完成。重开 Core.app 检查第一刀。"];
    } else {
        [self log:[NSString stringWithFormat:@"  ⚠️ 重签名失败：%@", err.localizedDescription]];
    }
    [self log:@"\n提示：第2/3刀（服务端/设备绑定）建议用 Frida 方案，"];
    [self log:@"      参见 CoreCrack.js / README.md。" ];
}

- (void)doRuntime {
    [self log:@"[②运行时] 尝试替换三方法 IMP ..."];
    NSDictionary *r = [CoreCrack crackRuntime];
    for (NSString *k in r) {
        [self log:[NSString stringWithFormat:@"  %@  ->  %@", k,
                    ([r[k] boolValue] ? @"✅ 已 hook" : @"❌ 未找到")]];
    }
    [self log:@"\n⚠️ 注意：运行时 hook 仅在本进程有效。"];
    [self log:@"  要 hook 已安装的 Core.app，请用 Frida（CoreCrack.js）："];
    [self log:@"  frida -U -f com.apple.manager -l CoreCrack.js --no-pause"];
}

@end

@interface CrackAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end
@implementation CrackAppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opt {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[CrackVC alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil,
                                 NSStringFromClass([CrackAppDelegate class]));
    }
}