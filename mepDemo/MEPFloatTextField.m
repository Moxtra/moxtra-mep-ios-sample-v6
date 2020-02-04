//
//  MXFloatTextField.m
//  MoxtraBinder
//
//  Created by wubright on 15/12/6.
//
//

#import <QuartzCore/QuartzCore.h>

#import "MEPFloatTextField.h"
#import "Masonry.h"

#define kMXFloatTextFieldHorizontalPadding 5.0f
#define kMXFloatTextFieldFloatPadding 6.0f

#define MEPGrayColor ([UIColor colorWithRed:221.0f/255.0f green:226.0f/255.0f blue:235.0f/255.0f alpha:1.0f])

@interface MEPFloatTextField()<UITextFieldDelegate>

@property(nonatomic, readwrite, strong) CALayer *borderLayer;
@property(nonatomic, readwrite, strong) UILabel *floatPlaceholderLabel;

@end

@implementation MEPFloatTextField

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.borderLayer = [CALayer layer];
        self.borderLayer.cornerRadius = 3.0f;
        self.borderLayer.borderColor = MEPGrayColor.CGColor;
        self.borderLayer.borderWidth = 1.0;
        [self.layer addSublayer:self.borderLayer];
        
        self.borderStyle = UITextBorderStyleNone;
        self.font = [UIFont boldSystemFontOfSize:15.0f];
        self.textAlignment = NSTextAlignmentLeft;
        self.clearButtonMode = UITextFieldViewModeNever;
        self.leftViewMode = UITextFieldViewModeUnlessEditing;
        self.textColor = [UIColor blackColor];
        [self addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

        [self addSubview:self.floatPlaceholderLabel];
        [self.floatPlaceholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(kMXFloatTextFieldHorizontalPadding);
            make.top.equalTo(self).offset(self.floatPlaceholderLabel.font.lineHeight);
        }];

        self.delegate = self;
    }
    return self;
}

- (UILabel *)floatPlaceholderLabel
{
    if(_floatPlaceholderLabel == nil)
    {
        _floatPlaceholderLabel = [UILabel new];
        _floatPlaceholderLabel.text = self.placeholder;
        _floatPlaceholderLabel.textAlignment = self.textAlignment;
        _floatPlaceholderLabel.font = [UIFont boldSystemFontOfSize:10];
        _floatPlaceholderLabel.alpha = 0.0f;
        [_floatPlaceholderLabel sizeToFit];
        _floatPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return _floatPlaceholderLabel;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.borderLayer.frame = self.bounds;
}

- (void)updateStatus;
{
    self.borderLayer.borderWidth = self.isEditing?1.0f:1.0;
    self.borderLayer.borderColor = self.isEditing?self.activeBorderColor.CGColor:MEPGrayColor.CGColor;
	
    [self.floatPlaceholderLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(self.text.length>0?kMXFloatTextFieldFloatPadding:self.floatPlaceholderLabel.font.lineHeight);
    }];
    self.floatPlaceholderLabel.alpha = self.text.length>0?1.0f:0.0f;
    self.floatPlaceholderLabel.textColor = self.isEditing?self.activeBorderColor:MEPGrayColor;
}

#pragma mark - private
-(void)setPlaceholder:(NSString *)placeholder
{
    self.attributedPlaceholder  = [[NSAttributedString alloc] initWithString:placeholder
                                                                  attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0f]}];
    self.floatPlaceholderLabel.text = placeholder;
    [self.floatPlaceholderLabel sizeToFit];
}

-(void)setActiveBorderColor:(UIColor *)activeBorderColor
{
    _activeBorderColor = activeBorderColor;
    [self updateStatus];
}

- (void)setAccessoryView:(UIView *)accessoryView
{
	if(accessoryView != _accessoryView)
	{
		[_accessoryView removeFromSuperview];
		_accessoryView = nil;
	}
	
	_accessoryView = accessoryView;
	[self addSubview:accessoryView];
	[accessoryView mas_makeConstraints:^(MASConstraintMaker *make) {
		make.right.equalTo(self).offset(-kMXFloatTextFieldHorizontalPadding);
		make.centerY.equalTo(self);
	}];
}

-(void)setText:(NSString *)text
{
    [super setText:text];
    [self updateStatus];
}

- (CGRect)insetRectForBounds:(CGRect)bounds
{
    CGFloat left = kMXFloatTextFieldHorizontalPadding;
    CGFloat top = 0.0f;
    CGFloat right = kMXFloatTextFieldHorizontalPadding;
    CGFloat bottom = 0.0f;
        
    if(self.accessoryView != nil)
    {
        right += self.accessoryView.bounds.size.width + kMXFloatTextFieldHorizontalPadding;
    }
    
    if(self.text.length > 0)
    {
        top += self.floatPlaceholderLabel.bounds.size.height + kMXFloatTextFieldFloatPadding;
    }
    
    return UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(top, left, bottom, right));
}

- (CGRect)editingRectForBounds:(CGRect)bounds;
{
    return [self insetRectForBounds:bounds];
}

- (CGRect)textRectForBounds:(CGRect)bounds;
{
    return [self insetRectForBounds:bounds];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField;
{
    [self updateStatus];
}

- (void)textFieldDidEndEditing:(UITextField *)textField;
{
    [self updateStatus];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string length]==0)
        return YES;
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > 128) ? NO : YES;
}

- (void)textFieldDidChange:(UITextField *)textField
{
    [self.floatPlaceholderLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(self.text.length>0?kMXFloatTextFieldFloatPadding:self.floatPlaceholderLabel.font.lineHeight);
    }];
    
    [UIView animateWithDuration:0.3f
					 animations:^{
        self.floatPlaceholderLabel.alpha = self.text.length>0?1.0f:0.0f;
        [self layoutIfNeeded];
    }];
    
    if(self.textFieldDidChange)
    {
        self.textFieldDidChange(self);
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textfield
{
    if(self.textFieldShouldReturn)
    {
        return self.textFieldShouldReturn(self);
    }
    else
    {
        return YES;
    }
}

@end
