//
//  MEPFloatTextField.h
//  MoxtraBinder
//
//  Created by wubright on 15/12/6.
//
//

#import <UIKit/UIKit.h>

@interface MEPFloatTextField : UITextField

@property(nonatomic, strong) UIColor *activeBorderColor;
@property(nonatomic, strong) UIView *accessoryView;

@property (nonatomic, copy) void (^textFieldDidChange)(MEPFloatTextField *textField);
@property (nonatomic, copy) BOOL (^textFieldShouldReturn)(MEPFloatTextField *textField);

- (void)updateStatus;

@end
