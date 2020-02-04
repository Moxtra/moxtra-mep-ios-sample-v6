//
//  ViewController.m
//  Prudential RM
//
//  Created by gitesh on 7/12/17.
//  Copyright © 2017 gitesh. All rights reserved.
//
#import <LocalAuthentication/LocalAuthentication.h>

#import "LoginViewController.h"
#import "MEPFloatTextField.h"
#import "Masonry.h"
#import "MEPInterfaceSampleViewController.h"
#import "NSURLSession+POST.h"

@interface LoginViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, assign) BOOL ignoreLoginError;
@property (nonatomic, strong) NSTimer *sessionTimer;
@property (nonatomic, assign) NSInteger sessionExpireInterval;


- (BOOL)isSessionExpired;

@end

@implementation LoginViewController

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
		
        [[MEPClient sharedInstance] setupWithDomain:MOXTRA_DOMAIN linkConfig:nil];
		[MEPClient sharedInstance].delegate = self;
        
        if ([MEPClient sharedInstance].isLinked)
        {
            [self appDidLogin];
        }

		self.sessionExpireInterval = 50000 * 60;

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationWillResignActiveNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												selector:@selector(applicationBecameActive:)
													name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

-(void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor whiteColor];
	
	self.edgesForExtendedLayout = UIRectEdgeNone;
	self.extendedLayoutIncludesOpaqueBars = NO;
	
	[self.scrollView addSubview:self.alarmLabel];
    [self.scrollView addSubview:self.titleLabel];
    [self.scrollView addSubview:self.uniqueIDTextField];
    [self.scrollView addSubview:self.loginButton];
    [self.scrollView addSubview:self.spinner];
	
	[self.view addSubview:self.logoView];
	[self.view addSubview:self.scrollView];
	[self.view addSubview:self.sdkVersionLabel];
	
	[self.alarmLabel mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.scrollView).offset(-46.0f);
		make.centerX.equalTo(self.scrollView);
		make.width.equalTo(self.scrollView);
		make.height.equalTo(@46.0f);
	}];
	[self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.alarmLabel.mas_bottom).offset(36.0f);
		make.centerX.equalTo(self.scrollView);
	}];
    [self.uniqueIDTextField mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.titleLabel.mas_bottom).offset(36.0f);
		make.height.mas_equalTo(60.0f);
		make.centerX.equalTo(self.view);
		make.width.equalTo(self.view).multipliedBy(0.92f);
		make.width.lessThanOrEqualTo(@(400)).priorityHigh();
    }];
    
	
#ifdef DEBUG
    self.uniqueIDTextField.text = DEFAULT_UNIQUEID;
#endif
    
    [self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.uniqueIDTextField.mas_bottom).offset(30.0f);
		make.height.mas_equalTo(54.0f);
		make.centerX.equalTo(self.scrollView);
		make.width.equalTo(self.uniqueIDTextField);
    }];
	
	
	[self.spinner mas_makeConstraints:^(MASConstraintMaker *make) {
		make.center.equalTo(self.view);
	}];
	
	
	[self.logoView mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.view);
		make.left.right.equalTo(self.view);
		make.height.equalTo(@150);
	}];
	
	[self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
		make.left.right.equalTo(self.view);
		make.top.equalTo(self.logoView.mas_bottom);
		make.bottom.equalTo(self.view).offset(-10);
	}];
	
    [self.sdkVersionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *))
        {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20.0f);
        }
        else
        {
            make.bottom.equalTo(self.view.mas_bottom).offset(-20.0f);
        }
        make.right.equalTo(self.view).offset(-16.0f);
    }];
	
	[self updateButtonStatus];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
	
    if ([self isSessionExpired])
        [[MEPClient sharedInstance] unlink];
    else if ([[MEPClient sharedInstance] isLinked])
    {
        [self appDidLogin];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		return UIInterfaceOrientationMaskAll;
	}
	else
	{
		return UIInterfaceOrientationMaskPortrait;
	}
}

- (void)updateButtonStatus
{
    BOOL isActive = (self.uniqueIDTextField.text.length > 0);
	
	self.loginButton.enabled = isActive;
    UIColor *color = isActive ? [UIColor blueColor] : [UIColor grayColor];
	[self.loginButton setBackgroundColor:color];
}

+ (BOOL)isEmail:(NSString *)email
{
	if(email.length == 0)
		return NO;
	static NSRegularExpression *g_regEx = nil;
	if( g_regEx == nil )
        g_regEx = [[NSRegularExpression alloc] initWithPattern:@"^[a-zA-Z0-9.'_%+-]+@([a-zA-Z0-9][a-zA-Z0-9-]{0,64})(\\.[a-zA-Z0-9][a-zA-Z0-9-]{0,25})+$" options:NSRegularExpressionCaseInsensitive error:nil];
	NSUInteger regExMatches = [g_regEx numberOfMatchesInString:email options:0 range:NSMakeRange(0, [email length])];
	if (regExMatches == 0)
		return NO;
	else
		return YES;
}

- (void)sessionExpireCheck
{
    if([self isSessionExpired] == YES)
    {
        [self.sessionTimer invalidate];
        self.sessionTimer = nil;
        [[MEPClient sharedInstance] unlink];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Session Expired", @"") message:NSLocalizedString(@"To continue, please log in again.", @"") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [[MEPClient sharedInstance] dismissMEPWindow];
        }]];
        
        UIWindow *topWindow = nil;
        for(UIWindow *window in [UIApplication sharedApplication].windows)
        {
            if(window.windowLevel >= topWindow.windowLevel)
            {
                topWindow = window;
            }
        }
        UIViewController *topViewController = [self topViewControllerForController:topWindow.rootViewController];
        if([topViewController isKindOfClass:[UIAlertController class]])
        {
            [topViewController dismissViewControllerAnimated:YES completion:^{
               [[self topViewControllerForController:topWindow.rootViewController] presentViewController:alertController animated:YES completion:nil];
            }];
        }
        else
        {
            [topViewController presentViewController:alertController animated:YES completion:nil];
        }
    }
}

- (UIViewController *)topViewControllerForController:(UIViewController *)controller
{
    if(controller.presentedViewController)
        return [self topViewControllerForController:controller.presentedViewController];
    return controller;
}

- (void)showMepWindow
{
    [[MEPClient sharedInstance] showMEPWindow];
	
	[self.sessionTimer invalidate];
    self.sessionTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(sessionExpireCheck) userInfo:nil repeats:YES];
}

#pragma mark - Property
-(UIScrollView *)scrollView
{
    if (!_scrollView)
    {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
		_scrollView.bounces = NO;
        _scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds), MAX(CGRectGetHeight(self.view.bounds), 568));
    }
    
    return _scrollView;
}

-(UIView *)logoView
{
    if (!_logoView)
    {
		_logoView = [UIView new];
		_logoView.backgroundColor = [UIColor blackColor];
		
		UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"login_logo"]];
        imageView.contentMode = UIViewContentModeCenter;
		[_logoView addSubview:imageView];
        __weak typeof(self) weakifySelf = self;
		[imageView mas_makeConstraints:^(MASConstraintMaker *make) {
			make.left.right.bottom.equalTo(weakifySelf.logoView);
			if (@available(iOS 11.0, *))
			{
				make.top.equalTo(weakifySelf.logoView.mas_safeAreaLayoutGuideTop);
			}
			else
			{
				make.top.equalTo(weakifySelf.logoView.mas_top).offset(20.0f);
			}
		}];
    }
    
    return _logoView;
}

-(UILabel *)titleLabel
{
    if (!_titleLabel)
    {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
        _titleLabel.text = NSLocalizedString(@"Login to Your Account", @"");
    }
    
    return _titleLabel;
}

- (UITextField *)uniqueIDTextField
{
    if(_uniqueIDTextField == nil)
    {
        _uniqueIDTextField = [MEPFloatTextField new];
		_uniqueIDTextField.activeBorderColor = [UIColor blackColor];
        _uniqueIDTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        _uniqueIDTextField.keyboardType = UIKeyboardTypeEmailAddress;
        _uniqueIDTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		_uniqueIDTextField.placeholder = NSLocalizedString(@"unique id", @"");
		_uniqueIDTextField.accessibilityIdentifier = @"login.uniqueid";
		if (@available(iOS 11.0, *))
		{
			_uniqueIDTextField.textContentType = UITextContentTypeUsername;
		}
		
		__weak typeof(self) weakSelf = self;
		_uniqueIDTextField.textFieldDidChange = ^(MEPFloatTextField *textField) {
			[weakSelf updateButtonStatus];
			weakSelf.alarmLabel.hidden = YES;
			[weakSelf.alarmLabel mas_updateConstraints:^(MASConstraintMaker *make) {
				make.top.equalTo(weakSelf.scrollView).offset(-46.0f);
			}];
			[UIView animateWithDuration:0.3f
							 animations:^{
								 [weakSelf.view layoutIfNeeded];
							 }
							 completion:nil];
		};
    }
    return _uniqueIDTextField;
}

-(UIButton *)showButton
{
    if (!_showButton)
    {
        _showButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_showButton setTitle:NSLocalizedString(@"Show", nil).uppercaseString forState:UIControlStateNormal];
        [_showButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _showButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
        _showButton.contentEdgeInsets = UIEdgeInsetsMake(10.0f, 0.0f, 10.0f, 0.0f);
        [_showButton addTarget:self action:@selector(showButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _showButton.hidden = YES;
		
		[_showButton sizeToFit];
    }
    
    return _showButton;
}

-(UILabel *)alarmLabel
{
	if (!_alarmLabel)
	{
		_alarmLabel = [UILabel new];
		_alarmLabel.backgroundColor = [UIColor colorWithRed:219.0f/255.0f green:70.0f/255.0f blue:70.0f/255.0f alpha:1.0f];
		_alarmLabel.textColor = [UIColor whiteColor];
		_alarmLabel.font = [UIFont boldSystemFontOfSize:15.0];
		_alarmLabel.textAlignment = NSTextAlignmentCenter;
		_alarmLabel.numberOfLines = 2;
		_alarmLabel.hidden = YES;
	}
	
	return _alarmLabel;
}

- (UIActivityIndicatorView *)spinner
{
    if(_spinner == nil)
    {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _spinner.color = [UIColor grayColor];
        _spinner.hidesWhenStopped = YES;
    }
    
    return _spinner;
}

- (UIButton *)loginButton
{
    if(_loginButton == nil)
    {
        _loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_loginButton setTitle:NSLocalizedString(@"Login", @"") forState:UIControlStateNormal];
		_loginButton.accessibilityIdentifier = @"login.login";
        [_loginButton addTarget:self action:@selector(loginButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [_loginButton.titleLabel setFont:[UIFont boldSystemFontOfSize:15]];
        [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[_loginButton setTitleColor:[UIColor colorWithRed:80.0f/255.0f green:80.0f/255.0f blue:80.0f/255.0f alpha:1.0f] forState:UIControlStateDisabled];
        _loginButton.backgroundColor = [UIColor blackColor];
    }
    
    return _loginButton;
}

- (UILabel *)sdkVersionLabel
{
    if(_sdkVersionLabel == nil)
    {
        _sdkVersionLabel = [UILabel new];
        _sdkVersionLabel.font = [UIFont systemFontOfSize:13];
        _sdkVersionLabel.textColor = [UIColor grayColor];
        _sdkVersionLabel.textAlignment = NSTextAlignmentRight;
		
		NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
		NSString* productBuildNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ProductBuildNumber"];
        _sdkVersionLabel.text = [NSString stringWithFormat:@"v%@ (%@)",version, productBuildNumber];
    }
    
    return _sdkVersionLabel;
}


- (BOOL)isSessionExpired
{
	if(self.sessionExpireInterval == 0)
		return NO;
	
	return ([MEPClient sharedInstance].lastActiveDate && [[NSDate date] timeIntervalSince1970] - [[MEPClient sharedInstance].lastActiveDate timeIntervalSince1970] >= self.sessionExpireInterval);
}

#pragma mark - Action

- (IBAction)loginButtonClicked:(UIButton *)sender
{
    [self.view endEditing:YES];
	
    [self performLogin];
}

- (void)performLogin
{
    NSString *uniqudID = self.uniqueIDTextField.text;
	
    [self hideFields:true];
	
	__weak typeof(self) weakSelf = self;
    NSDictionary *requestBody = @{@"client_id": CLIENT_ID,
                                  @"client_secret": CLIENT_Secret,
                                  @"unique_id": uniqudID,
                                  @"org_id": ORG_ID};
    [NSURLSession mx_postWithURL:[NSString stringWithFormat:@"https://%@/v1/core/oauth/token", MOXTRA_DOMAIN] headers:@{@"Content-Type":@"application/json"} requestBody:requestBody delegate:nil
                         success:^(NSUInteger httpCode, NSDictionary * _Nullable json) {
                             NSString *token = [json objectForKey:@"access_token"];
                             if (token.length)
                             {
                                 [[MEPClient sharedInstance] linkUserWithAccessToken:token completionHandler:^(NSError * _Nullable errorOrNil) {
                                     if (!errorOrNil)
                                     {
                                         //register notifications.
                                         UIUserNotificationType notificationType = UIUserNotificationTypeSound | UIUserNotificationTypeBadge | UIUserNotificationTypeAlert;
                                         UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:notificationType categories:nil];
                                         [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
                                         //
                                         [weakSelf hideFields:NO];
                                         [weakSelf appDidLogin];
    #ifndef DEBUG
                                         self.uniqueIDTextField.text = @"";
    #endif
                                     }
                                     else
                                     {
                                         [weakSelf alertError:errorOrNil];
                                          [weakSelf hideFields:NO];
                                         [weakSelf updateButtonStatus];
                                     }
                                 }];
                             }
                             else
                             {
                                 NSString *message = [json objectForKey:@"message"];
                                 NSError *error = [NSError errorWithDomain:MEPSDKErrorDomain code:MEPInvalidAccountError userInfo:message ? [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey] : nil];
                                 [weakSelf alertError:error];
                                 [weakSelf hideFields:NO];
                                 [weakSelf updateButtonStatus];
                             }
                             [weakSelf updateButtonStatus];
                         } failure:^(NSError * _Nonnull error) {
                             [weakSelf hideFields:false];
                             [weakSelf alertError:error];
                         }];
}

-(void)hideFields:(Boolean)hide
{
    [self.uniqueIDTextField setHidden:hide]; 
    [self.loginButton setHidden:hide];
	
    if (hide)
	{
        [self.spinner startAnimating];
    }
	else
	{
        [self.spinner stopAnimating];
    }
}

- (SecAccessControlRef)createAccessControl:(CFErrorRef *)error;
{
	return SecAccessControlCreateWithFlags(NULL, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlUserPresence, error);
}

-(void)viewTapped:(UITapGestureRecognizer*)tap
{
    [self.uniqueIDTextField resignFirstResponder];
}

- (void)alertError:(NSError *)error
{
	NSString *alarmMessage = error.localizedDescription;
	if(error.code == MEPInvalidAccountError)
	{
		alarmMessage = NSLocalizedString(@"Incorrect account", @"");
	}
	else if(error.code == 0)
	{
		alarmMessage = NSLocalizedString(@"The account associated with this email address is no longer active.", @"");
	}
	
	self.alarmLabel.text = alarmMessage;
	self.alarmLabel.hidden = NO;
	[self.alarmLabel mas_updateConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.scrollView).offset(0.0f);
	}];
	
	[UIView animateWithDuration:0.3f
					 animations:^{
						 [self.view layoutIfNeeded];
					 }
					 completion:nil];
}

- (void)appDidLogin
{
    MEPInterfaceSampleViewController *sampleCtrl = [[MEPInterfaceSampleViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:sampleCtrl];
    [navigationController navigationBar].backgroundColor = [UIColor blueColor];
    navigationController.navigationBar.tintColor = [UIColor colorWithRed:247.0f/255.0f green:247.0f/255.0f blue:247.0f/255.0f alpha:1.0f];
    navigationController.navigationBar.barTintColor = [UIColor blueColor];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self presentViewController:navigationController animated:YES completion:nil];
    });
}

- (void)appDidLogout
{
    
}

#pragma mark - Notification
- (void)applicationWillResignActiveNotification:(NSNotification *)notification
{
	[self.sessionTimer invalidate];
	self.sessionTimer = nil;
}

- (void)applicationBecameActive:(NSNotification *)notification
{
	if([MEPClient sharedInstance].isLinked == YES)
	{
		if([self isSessionExpired] == YES)
		{
			[self.sessionTimer invalidate];
			self.sessionTimer = nil;
			[[MEPClient sharedInstance] unlink];
			[[MEPClient sharedInstance] dismissMEPWindow];
		}
		else
		{
			if(self.sessionTimer == nil)
			{
				self.sessionTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(sessionExpireCheck) userInfo:nil repeats:YES];
			}
		}
	}
}

#pragma mark - MEPClientDelegate
- (void)client:(MEPClient *)client didTapClose:(id)sender
{
    NSLog(@"client:didTapClose:");
    [[MEPClient sharedInstance] dismissMEPWindow];
}

- (void)clientDidLogout:(MEPClient *)client;
{
    NSLog(@"client:didTapClose:");
    [self appDidLogout];
}


@end
