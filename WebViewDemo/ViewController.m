//
//  ViewController.m
//  WebViewDemo
//
//  Created by User on 7/3/18.
//  Copyright © 2018 User. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>

#define WIDTH_SCREEN (CGRectGetWidth([[UIScreen mainScreen] bounds]))
#define HEIGHT_SCREEN (CGRectGetHeight([[UIScreen mainScreen] bounds]))

@interface ViewController ()<WKUIDelegate, WKNavigationDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong, readonly) WKWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initWebView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initWebView {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.preferences.minimumFontSize = 9.0;
    configuration.allowsInlineMediaPlayback = YES;
    
    if (@available(iOS 9.0, *)) {
        [configuration setApplicationNameForUserAgent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
    }
    
    if (@available(iOS 10.0, *)) {
        [configuration setMediaTypesRequiringUserActionForPlayback:WKAudiovisualMediaTypeNone];
    } else if (@available(iOS 9.0, *)) {
        [configuration setRequiresUserActionForMediaPlayback:NO];
    } else {
        [configuration setMediaPlaybackRequiresUserAction:NO];
    }
    
    
    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 64, WIDTH_SCREEN, HEIGHT_SCREEN-64) configuration:configuration];
    [self.view addSubview:_webView];
    _webView.navigationDelegate = self;
    _webView.allowsBackForwardNavigationGestures = YES;
    _webView.UIDelegate = self;
    if (@available(iOS 9.0, *)) {
        _webView.allowsLinkPreview = YES;
    }
    
    NSMutableString *javascripts = [NSMutableString string];
    // 禁止长按
    [javascripts appendString:@"document.documentElement.style.webkitTouchCallout='none';"];
    // 禁止选择
    [javascripts appendString:@"document.documentElement.style.webkitUserSelect='none';"];
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:javascripts injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [_webView.configuration.userContentController addUserScript:userScript];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"xx" ofType:@"html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]];
    [_webView loadRequest:request];
    
    UILongPressGestureRecognizer *ges = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longGes:)];
    ges.delegate = self;
    [_webView addGestureRecognizer:ges];
}

#pragma mark - WKUIDelegate

- (nullable WKWebView *)webView:(WKWebView *)webView
 createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
            forNavigationAction:(WKNavigationAction *)navigationAction
                 windowFeatures:(WKWindowFeatures *)windowFeatures
{
    WKFrameInfo *frameInfo = navigationAction.targetFrame;
    if (![frameInfo isMainFrame]) {
        if (navigationAction.request) {
            [webView loadRequest:navigationAction.request];
        }
    }
    return nil;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
- (void)webViewDidClose:(WKWebView *)webView {
}
#endif

- (void)webView:(WKWebView *)webView
runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(void))completionHandler
{
    // Get host name of url.
    NSString *host = webView.URL.host;
    // Init the alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:@"来自网页的消息" message:message preferredStyle: UIAlertControllerStyleAlert];
    // Init the cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (completionHandler != NULL) {
            completionHandler();
        }
    }];
    // Init the ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler();
        }
    }];
    
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)webView:(WKWebView *)webView
runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(BOOL result))completionHandler
{
    // Get the host name.
    NSString *host = webView.URL.host;
    // Initialize alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:@"来自网页的消息" message:message preferredStyle:UIAlertControllerStyleAlert];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler(NO);
        }
    }];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler(YES);
        }
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)webView:(WKWebView *)webView
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
    defaultText:(nullable NSString *)defaultText
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSString * __nullable result))completionHandler
{
    // Get the host of url.
    NSString *host = webView.URL.host;
    // Initialize alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:prompt?:@"来自网页的消息" message:host preferredStyle:UIAlertControllerStyleAlert];
    // Add text field.
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = defaultText?:@"输入文字消息";
        textField.font = [UIFont systemFontOfSize:12];
    }];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        // Get inputed string.
        NSString *string = [alert.textFields firstObject].text;
        if (completionHandler != NULL) {
            completionHandler(string?:defaultText);
        }
    }];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        // Get inputed string.
        NSString *string = [alert.textFields firstObject].text;
        if (completionHandler != NULL) {
            completionHandler(string?:defaultText);
        }
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:NULL];
}

#pragma mark - WKWebView NavigationDelegate

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    // Disable all the '_blank' target in page's target.
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView evaluateJavaScript:@"var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','');}" completionHandler:nil];
    }
    
//    NSURLComponents *components = [[NSURLComponents alloc] initWithString:navigationAction.request.URL.absoluteString];
//    // For appstore and system defines. This action will jump to AppStore app or the system apps.
//    if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/' OR SELF BEGINSWITH[cd] 'mailto:' OR SELF BEGINSWITH[cd] 'tel:' OR SELF BEGINSWITH[cd] 'telprompt:'"] evaluateWithObject:components.URL.absoluteString]) {
//        if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/'"] evaluateWithObject:components.URL.absoluteString]) {
//            SKStoreProductViewController *productVC = [[SKStoreProductViewController alloc] init];
//            productVC.delegate = self;
//            NSError *error;
//            NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"id[1-9]\\d*" options:NSRegularExpressionCaseInsensitive error:&error];
//            NSTextCheckingResult *result = [regex firstMatchInString:components.URL.absoluteString options:NSMatchingReportCompletion range:NSMakeRange(0, components.URL.absoluteString.length)];
//
//            if (!error && result) {
//                NSRange range = NSMakeRange(result.range.location+2, result.range.length-2);
//                [productVC loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: @([[components.URL.absoluteString substringWithRange:range] integerValue])} completionBlock:nil];
//                [self presentViewController:productVC animated:YES completion:NULL];
//                decisionHandler(WKNavigationActionPolicyCancel);
//            }
//        }
//        if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
//            if (AVAILABLE(10.0)) {
//                [UIApplication.sharedApplication openURL:components.URL options:@{} completionHandler:NULL];
//            } else {
//                [[UIApplication sharedApplication] openURL:components.URL];
//            }
//        }
//        decisionHandler(WKNavigationActionPolicyCancel);
//        return;
//    } else if (![[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] 'https' OR SELF MATCHES[cd] 'http' OR SELF MATCHES[cd] 'file' OR SELF MATCHES[cd] 'about'"] evaluateWithObject:components.scheme]) {// For any other schema but not `https`、`http` and `file`.
//        if (AVAILABLE(8.0)) { // openURL if ios version is low then 8 , app will crash
//            if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
//                if (AVAILABLE(10.0)) {
//                    [UIApplication.sharedApplication openURL:components.URL options:@{} completionHandler:NULL];
//                } else {
//                    [[UIApplication sharedApplication] openURL:components.URL];
//                }
//            }
//        } else {
//            if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
//                [[UIApplication sharedApplication] openURL:components.URL];
//            }
//        }
//
//        decisionHandler(WKNavigationActionPolicyCancel);
//        return;
//    }
    
    // Call the decision handler to allow to load web page.
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {}

- (void)webView:(WKWebView *)webView
didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation
      withError:(NSError *)error
{
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}
- (void)webView:(WKWebView *)webView
didFailNavigation:(null_unspecified WKNavigation *)navigation
      withError:(NSError *)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)webView:(WKWebView *)webView
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler
{
    // !!!: Do add the security policy if using a custom credential.
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    // Get the host name.
    NSString *host = webView.URL.host;
    // Initialize alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:@"来自网页的消息" message:@"网页进程终止" preferredStyle:UIAlertControllerStyleAlert];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:NULL];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
}
#endif

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        //只有当手势为长按手势时反馈，飞长按手势将阻止。
        return YES;
    }else{
        return NO;
    }
}

- (void)longGes:(UILongPressGestureRecognizer *)ges {
    if (ges.state == UIGestureRecognizerStateBegan) {
        return;
    }
    
    CGPoint touchPoint = [ges locationInView:ges.view];
    touchPoint.y -= 64;
    
    NSString *jsStr = [NSString stringWithFormat:@"document.elementFromPoint(%.0f, %.0f).src", touchPoint.x, touchPoint.y];
    [_webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable param, NSError * _Nullable error) {
        NSLog(@"%@", param);
    }];
    
}

@end
