//
//  ViewController.m
//  AppleBuy
//
//  Created by 张冠清 on 16/2/26.
//  Copyright © 2016年 buyforyou. All rights reserved.
//

#import "ViewController.h"

#import "ViewController.h"
#import <StoreKit/StoreKit.h>
#define PRODUCTID @"" //商品ID（请填写你商品的id）
@interface ViewController () <SKPaymentTransactionObserver, SKProductsRequestDelegate>
@property (strong, nonatomic) SKPayment *payment;
@property (strong, nonatomic) SKMutablePayment *g_payment;

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    //添加一个交易队列观察者
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    //测试按钮
    UIButton *tesBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 40)];
    tesBtn.backgroundColor = [UIColor redColor];
    [tesBtn addTarget:self action:@selector(testPay) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:tesBtn];
}
- (void)testPay {
    //判断是否可进行支付
    if ([SKPaymentQueue canMakePayments]) {
        [self requestProductData:PRODUCTID];
    } else {
        NSLog(@"不允许程序内付费");
    }
}
- (void)requestProductData:(NSString *)type {
    //根据商品ID查找商品信息
    NSArray *product = [[NSArray alloc] initWithObjects:type, nil];
    NSSet *nsset = [NSSet setWithArray:product];
    //创建SKProductsRequest对象，用想要出售的商品的标识来初始化， 然后附加上对应的委托对象。
    //该请求的响应包含了可用商品的本地化信息。
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
    request.delegate = self;
    [request start];
}
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    //接收商品信息
    NSArray *product = response.products;
    if ([product count] == 0) {
        return;
    }
    // SKProduct对象包含了在App Store上注册的商品的本地化信息。
    SKProduct *storeProduct = nil;
    for (SKProduct *pro in product) {
        if ([pro.productIdentifier isEqualToString:PRODUCTID]) {
            storeProduct = pro;
        }
    }
    //创建一个支付对象，并放到队列中
    self.g_payment = [SKMutablePayment paymentWithProduct:storeProduct];
    //设置购买的数量
    self.g_payment.quantity = 1;
    [[SKPaymentQueue defaultQueue] addPayment:self.g_payment];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"请求商品失败%@", error);
}

- (void)requestDidFinish:(SKRequest *)request {
    NSLog(@"反馈信息结束调用");
}
//监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transaction {
    for (SKPaymentTransaction *tran in transaction) {
        // 如果小票状态是购买完成
        if (SKPaymentTransactionStatePurchased == tran.transactionState) {
            [[SKPaymentQueue defaultQueue] finishTransaction:tran];
            // 更新界面或者数据，把用户购买得商品交给用户
            //返回购买的商品信息
            [self verifyPruchase];
            //商品购买成功可调用本地接口
        } else if (SKPaymentTransactionStateRestored == tran.transactionState) {
            // 将交易从交易队列中删除
            [[SKPaymentQueue defaultQueue] finishTransaction:tran];
        } else if (SKPaymentTransactionStateFailed == tran.transactionState) {
            // 支付失败
            // 将交易从交易队列中删除
            [[SKPaymentQueue defaultQueue] finishTransaction:tran];
        }
    }
}
//交易结束
- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"交易结束");
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}
#pragma mark 验证购买凭据

- (void)verifyPruchase {
    // 验证凭据，获取到苹果返回的交易凭据
    // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    // 从沙盒中获取到购买凭据
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    // 发送网络POST请求，对购买凭据进行验证
    //测试验证地址:https://sandbox.itunes.apple.com/verifyReceipt
    //正式验证地址:https://buy.itunes.apple.com/verifyReceipt
    NSURL *url = [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
    NSMutableURLRequest *urlRequest =
    [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f];
    urlRequest.HTTPMethod = @"POST";
    NSString *encodeStr = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSString *payload = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\"}", encodeStr];
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    urlRequest.HTTPBody = payloadData;
    // 提交验证请求，并获得官方的验证JSON结果 iOS9后更改了另外的一个方法
    NSData *result = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:nil];
    // 官方验证结果为空
    if (result == nil) {
        NSLog(@"验证失败");
        return;
    }
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:result options:NSJSONReadingAllowFragments error:nil];
    if (dict != nil) {
        // 比对字典中以下信息基本上可以保证数据安全
        // bundle_id , application_version , product_id , transaction_id
        NSLog(@"验证成功！购买的商品是：%@", @"_productName");
    }
}
@end
