//
//  ViewController.m
//  Skea
//
//  Created by mosn on 9/30/14.
//  Copyright (c) 2014 com.dlnu.*. All rights reserved.
//

#import "ViewController.h"
#import "InfoViewController.h"
#import "GameViewController.h"
#import "LoginViewController.h"
#import "PersonViewController.h"
#import "RecordViewController.h"
#import "PersonLoginedViewController.h"
#import "SkeaUser.h"
#import "TestingViewController1.h"

@interface ViewController ()

@property (strong,nonatomic) IBOutlet UILabel *lbLevel;
@property (strong,nonatomic) IBOutlet UILabel *lbResult;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.titleView = [[Theam currentTheam] navigationTitleViewWithTitle:@"请连接Skea"];
    self.navigationItem.rightBarButtonItem = [[Theam currentTheam] navigationBarRightButtonItemWithImage:IMG(@"bluetooth-disconnected.png") Title:nil Target:self Selector:@selector(connectAction:)];
    self.view.backgroundColor = [UIColor colorWithRed:249/255.f green:249/255.f blue:249/255.f alpha:1.f];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didConnectBL:) name:kNotificationConnected object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDisConnectBL:) name:kNotificationDisConnected object:nil];
    if([SkeaUser defaultUser].isLogin)
    {
        IMP_BLOCK_SELF(LoginViewController);
        [[BaseEngine sharedEngine] RunRequest:[@{@"email":[SkeaUser defaultUser].email} mutableCopy] path:SK_LAST_QUS completionHandler:^(id responseObject) {
        } errorHandler:^(NSError *error) {
        } finishHandler:^(id responseObject) {
            if (responseObject!=nil) {
                int statusCode = [[responseObject objectForKey:@"status"] intValue];
                if (statusCode>100) {
                    NSString *errMsg = @"服务器错误";
                    switch (statusCode) {
                        case 101:
                            errMsg = @"参数错误";
                            break;
                        case 102:
                            errMsg = @"该用户已被注册";
                            break;
                        case 103:
                            errMsg = @"用户名或密码错误";
                            break;
                        case 104:
                        {
                            errMsg = @"结果未找到";
                            TestingViewController1 * tvc = [[TestingViewController1 alloc] init];
                            tvc._isRegisterPush = YES;
                            UINavigationController * nvc = [[UINavigationController alloc] initWithRootViewController:tvc];
                            [block_self presentViewController:nvc animated:YES completion:nil];
                        }
                            break;
                        default:
                            break;
                    }
                }
            }
        }];
    }
    // Do any additional setup after loading the view, typically from a nib.
}
/*
 问卷结---->{
 info =     {
 birthday = "1980-01-01";
 date = "2014-12-12";
 height = 103cm;
 result = "{\"Mother w";
 username = "yy16@qq.com";
 weight = 32kg;
 };
 status = 100;
 }

 */
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.lbLevel.text = _S(@"Level %d",[AppConfig getGameLevel]);
    GameDetail *detail = [AppConfig getLastGameDetail];
    
    
    
    if (detail) {
        self.lbResult.text = _S(@"Last Result:%d%%",(int)((detail.factScore*1.0/detail.heighScore)*100));
    }
    else{
        self.lbResult.text = nil;
    }
    
}

#pragma mark -
#pragma mark Action
- (void)connectAction:(id)sender
{
    
    int count = (int)[bleCentralManager shareManager].blePeripheralArray.count;
    if (count>1) {
        CTActionSheet *sheet = [[CTActionSheet alloc] initWithTitle:@"选择玩具" cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil HandleBlock:^(int btnIndex) {
            if (btnIndex<count) {
                blePeripheral *blItem = [[bleCentralManager shareManager].blePeripheralArray objectAtIndex:btnIndex];
                [[bleCentralManager shareManager] connectPeripheral:blItem.activePeripheral];
                
            }
        }];
        
        for (int i=0; i<count; i++) {
            blePeripheral *blItem = [[bleCentralManager shareManager].blePeripheralArray objectAtIndex:i];
            [sheet addButtonWithTitle:blItem.nameString];
        }
        [sheet addButtonWithTitle:@"Cancel"];
        [sheet setDestructiveButtonIndex:count];
        [sheet showInView:self.view];
    }
    else if (count==1){
        blePeripheral *blItem = [[bleCentralManager shareManager].blePeripheralArray objectAtIndex:0];
        [[bleCentralManager shareManager] connectPeripheral:blItem.activePeripheral];
        
    }
    else{
        showCustomAlertMessage(@"请打开Skea");
    }
    
}

#pragma mark - info按钮

- (IBAction)infoAction:(id)sender
{
    InfoViewController *ivc = [[InfoViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:ivc];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - 游戏按钮

- (IBAction)gameAction:(id)sender
{
    GameViewController *gvc = [[GameViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:gvc];
    [self presentViewController:nav animated:YES completion:nil];

}

#pragma mark - record按钮

- (IBAction)recordAction:(id)sender
{
    if([SkeaUser defaultUser].isLogin)
    {      
        RecordViewController *rvc = [[RecordViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rvc];
        [self presentViewController:nav animated:YES completion:nil];
    }
    else
    {
        LoginViewController *lvc = [[LoginViewController alloc] init];
        [self presentViewController:lvc animated:YES completion:nil];
    }

}

#pragma mark - 设置按钮

- (IBAction)settingAction:(id)sender
{
    if([SkeaUser defaultUser].isLogin)
    {
        PersonLoginedViewController *pvc = [[PersonLoginedViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:pvc];
        [self presentViewController:nav animated:YES completion:nil];
    }
    else
    {
        LoginViewController *lvc = [[LoginViewController alloc] init];
        [self presentViewController:lvc animated:YES completion:nil];
    }

}


#pragma mark -
#pragma mark BL
- (void)didConnectBL:(NSNotification *)notify
{
    NSDictionary *dict = [notify userInfo];
    if (dict) {
        blePeripheral *cp = [dict objectForKey:@"bl"];
        self.navigationItem.rightBarButtonItem = [[Theam currentTheam] navigationBarRightButtonItemWithImage:IMG(@"bluetooth-connected.png") Title:nil Target:self Selector:@selector(connectAction:)];
        self.navigationItem.titleView = [[Theam currentTheam] navigationTitleViewWithTitle:@"Skea"];
    }
}

- (void)didDisConnectBL:(NSNotification *)notify
{
    self.navigationItem.titleView = [[Theam currentTheam] navigationTitleViewWithTitle:@"请连接Skea"];
    self.navigationItem.rightBarButtonItem = [[Theam currentTheam] navigationBarRightButtonItemWithImage:IMG(@"bluetooth-disconnected.png") Title:nil Target:self Selector:@selector(connectAction:)];
}

@end
