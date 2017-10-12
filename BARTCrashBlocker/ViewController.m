//
//  ViewController.m
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/9.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

#import "ViewController.h"
#import "BARTKVOCrashBlocker.h"
#import "BARTDeallocObserver.h"

@interface TestInnerModel : NSObject

@property (nonatomic) NSString *style;
@property (nonatomic) UIImage *image;

@end

@implementation TestInnerModel

@end

@interface TestModel : NSObject

@property (nonatomic) NSString *style;
@property (nonatomic) UIImage *image;
@property (nonatomic) TestInnerModel *innerModel;

@end

@implementation TestModel

@end

@interface TestObserver : NSObject

@property (nonatomic) UIImage *image;

@end

@implementation TestObserver

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context
{
    NSLog(@"---------  %@", keyPath);
}

@end

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    UIButton *button = [[UIButton alloc] init];
    button.frame = CGRectMake(50, 50, 50, 50);
    button.layer.borderColor = [UIColor redColor].CGColor;
    button.layer.borderWidth = 1;
    [button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)buttonAction
{
    TestObserver *testObserver = [[TestObserver alloc] init];
    testObserver.image = [UIImage imageNamed:@"testImage"];
    [testObserver startDeallocObserving:^(){
        NSLog(@"will  1111111");
    } didDeallocBlock:nil];
    TestModel *testModel = [[TestModel alloc] init];
    [testModel startDeallocObserving:^(){
        NSLog(@"will  2222222");
    } didDeallocBlock:^(){
        NSLog(@"did  2222222");
    }];
    [testModel stopDeallocObserving];
    testModel.image = [UIImage imageNamed:@"testImage"];
    [testModel addObserver:testObserver forKeyPath:@"innerModel.style" options:NSKeyValueObservingOptionNew context:nil];
    [testModel addObserver:testObserver forKeyPath:@"style" options:NSKeyValueObservingOptionNew context:nil];
    testModel.style = @"hhhhhh";
    testObserver = nil;
    testModel.style = @"yyyyyy";
    NSLog(@"---end");
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectorAction) name:@"hhhhh" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)selectorAction
{
    
}

@end
