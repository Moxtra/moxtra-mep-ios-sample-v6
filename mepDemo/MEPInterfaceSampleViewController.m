//
//  MEPInterfaceSampleViewController.m
//  mepDemo
//
//  Created by jacob on 4/11/19.
//  Copyright © 2019 com.moxtra.mepdemo. All rights reserved.
//

#import "MEPInterfaceSampleViewController.h"
#import <MEPSDK/MEPSDK.h>
#import "Masonry.h"

@interface MEPInterfaceSampleViewController ()
@property (strong) UIButton *showMEPWindowBtn;
@property (strong) UIButton *showMEPWindowLiteBtn;
@property (strong) UIButton *changeLanguageBtn;
@end

@implementation MEPInterfaceSampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *logoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [logoutButton setTitle:NSLocalizedString(@"Logout", @"Back") forState:UIControlStateNormal];
    [logoutButton addTarget:self action:@selector(logout:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:logoutButton];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.showMEPWindowBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.showMEPWindowBtn addTarget:self action:@selector(showMEPWindow:) forControlEvents:UIControlEventTouchUpInside];
    [self.showMEPWindowBtn setTitle:NSLocalizedString(@"showMEPWindow", @"") forState:UIControlStateNormal];
    [self.view addSubview:self.showMEPWindowBtn];
    [self.showMEPWindowBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).mas_offset(120.0f);
    }];
    
    UIView *topView = self.showMEPWindowBtn;
    self.showMEPWindowLiteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.showMEPWindowLiteBtn addTarget:self action:@selector(showMEPWindowLite:) forControlEvents:UIControlEventTouchUpInside];
    [self.showMEPWindowLiteBtn setTitle:NSLocalizedString(@"showMEPWindowLite", @"") forState:UIControlStateNormal];
    [self.view addSubview:self.showMEPWindowLiteBtn];
    [self.showMEPWindowLiteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(topView.mas_bottom).mas_offset(10.0f);
    }];
    
    
    topView = self.showMEPWindowLiteBtn;
    self.changeLanguageBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.changeLanguageBtn addTarget:self action:@selector(changeLanguage:) forControlEvents:UIControlEventTouchUpInside];
    [self.changeLanguageBtn setTitle:NSLocalizedString(@"Change language", @"") forState:UIControlStateNormal];
    [self.view addSubview:self.changeLanguageBtn];
    [self.changeLanguageBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(topView.mas_bottom).mas_offset(10.0f);
    }];
}

- (void)logout:(id)sender
{
    [[MEPClient sharedInstance] unlink];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showMEPWindow:(id)sender
{
    [[MEPClient sharedInstance] changeLanguage:@"en_US"];
    [[MEPClient sharedInstance] showMEPWindow];
}

- (void)showMEPWindowLite:(id)sender
{
    [[MEPClient sharedInstance] changeLanguage:@"en_US"];
    [[MEPClient sharedInstance] showMEPWindowLite];
}


- (void)changeLanguage:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Change language", @"")
                                                                   message:nil
                                                            preferredStyle:(UIAlertControllerStyle)UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Traditional Chinese" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[MEPClient sharedInstance] changeLanguage:@"zh-Hant"];
        [[MEPClient sharedInstance] showMEPWindow];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Chinese" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[MEPClient sharedInstance] changeLanguage:@"zh-Hans"];
        [[MEPClient sharedInstance] showMEPWindow];
    }]];
    
    
    [alert addAction:[UIAlertAction actionWithTitle:@"English" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[MEPClient sharedInstance] changeLanguage:@"en_US"];
        [[MEPClient sharedInstance] showMEPWindow];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
