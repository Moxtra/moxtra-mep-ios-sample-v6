//
//  ViewController.h
//  Prudential RM
//
//  Created by gitesh on 7/12/17.
//  Copyright © 2017 gitesh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MEPSDK/MEPSDK.h>

@class MEPFloatTextField;


@interface LoginViewController : UIViewController<MEPClientDelegate>

@property (nonatomic, strong) UIView *logoView;

@property (nonatomic, strong) MEPFloatTextField *uniqueIDTextField;
@property (nonatomic, strong) UIButton *showButton;
@property (nonatomic, strong) UILabel *alarmLabel;
@property (nonatomic, strong) UILabel *titleLabel;


@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIButton *loginButton;

@property (nonatomic, strong) UILabel *sdkVersionLabel;

- (void)updateButtonStatus;
- (IBAction)loginButtonClicked:(UIButton *)sender;
- (void)hideFields:(Boolean)hide;
- (void)showMepWindow;
- (void)alertError:(NSError *)error;

- (void)appDidLogin;
@end

