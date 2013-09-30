//
//  PXAlertView.m
//  PXAlertViewDemo
//
//  Created by Alex Jarvis on 25/09/2013.
//  Copyright (c) 2013 Panaxiom Ltd. All rights reserved.
//

#import "PXAlertView.h"

static const CGFloat AlertViewWidth = 250.0;
static const CGFloat AlertViewContentMargin = 5;
static const CGFloat AlertViewVerticalElementSpace = 10;
static const CGFloat AlertViewButtonHeight = 44;

@interface PXAlertView ()

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UIView *alertView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) UIButton *cancelButton;
@property (nonatomic) UIButton *otherButton;
@property (nonatomic) UITapGestureRecognizer *tap;
@property (nonatomic, strong) void (^completion)(BOOL cancelled);

@end

@implementation PXAlertView

- (id)initAlertWithTitle:(NSString *)title
                 message:(NSString *)message
             cancelTitle:(NSString *)cancelTitle
              otherTitle:(NSString *)otherTitle
              completion:(void(^) (BOOL cancelled))completion
{
    self = [super init];
    if (self) {
        // Initialization code
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        self.frame = keyWindow.bounds;
        
        _backgroundView = [[UIView alloc] initWithFrame:keyWindow.bounds];
        _backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25];
        _backgroundView.alpha = 0;
        [self addSubview:_backgroundView];
        
        _alertView = [[UIView alloc] init];
        _alertView.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1];
        _alertView.layer.cornerRadius = 8.0;
        _alertView.layer.opacity = .95;
        _alertView.clipsToBounds = YES;
        [self addSubview:_alertView];
        
        // Title
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(AlertViewContentMargin,
                                                                AlertViewVerticalElementSpace,
                                                                AlertViewWidth - AlertViewContentMargin*2,
                                                                44)];
        _titleLabel.text = title;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont boldSystemFontOfSize:17];
        _titleLabel.frame = [self adjustLabelFrameHeight:self.titleLabel];
        [_alertView addSubview:_titleLabel];
        
        // Message
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(AlertViewContentMargin,
                                                                  _titleLabel.frame.origin.y + _titleLabel.frame.size.height + AlertViewVerticalElementSpace,
                                                                  AlertViewWidth - AlertViewContentMargin*2,
                                                                  44)];
        _messageLabel.text = message;
        _messageLabel.backgroundColor = [UIColor clearColor];
        _messageLabel.textColor = [UIColor whiteColor];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.font = [UIFont systemFontOfSize:15];
        _messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _messageLabel.numberOfLines = 0;
        _messageLabel.frame = [self adjustLabelFrameHeight:self.messageLabel];
        [_alertView addSubview:_messageLabel];
        
        // Line
        CALayer *lineLayer = [CALayer layer];
        lineLayer.backgroundColor = [[UIColor colorWithWhite:0.90 alpha:0.3] CGColor];
        lineLayer.frame = CGRectMake(0, _messageLabel.frame.origin.y + _messageLabel.frame.size.height + AlertViewVerticalElementSpace, AlertViewWidth, 0.5);
        [_alertView.layer addSublayer:lineLayer];
        
        // Buttons
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setTitle:cancelTitle forState:UIControlStateNormal];
        _cancelButton.backgroundColor = [UIColor clearColor];
        
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor colorWithWhite:0.25 alpha:1] forState:UIControlStateHighlighted];
        [_cancelButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
        [_cancelButton addTarget:self action:@selector(setBackgroundColorForButton:) forControlEvents:UIControlEventTouchDown];
        [_cancelButton addTarget:self action:@selector(clearBackgroundColorForButton:) forControlEvents:UIControlEventTouchDragExit];

        CGFloat buttonsY = lineLayer.frame.origin.y + lineLayer.frame.size.height;
        if (otherTitle) {
            _cancelButton.titleLabel.font = [UIFont systemFontOfSize:17];
            _cancelButton.frame = CGRectMake(0, buttonsY, AlertViewWidth/2, AlertViewButtonHeight);
            
            _otherButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [_otherButton setTitle:otherTitle forState:UIControlStateNormal];
            _otherButton.backgroundColor = [UIColor clearColor];
            _otherButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
            [_otherButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_otherButton setTitleColor:[UIColor colorWithWhite:0.25 alpha:1] forState:UIControlStateHighlighted];
            [_otherButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
            [_otherButton addTarget:self action:@selector(setBackgroundColorForButton:) forControlEvents:UIControlEventTouchDown];
            [_otherButton addTarget:self action:@selector(clearBackgroundColorForButton:) forControlEvents:UIControlEventTouchDragExit];
            _otherButton.frame = CGRectMake(_cancelButton.frame.size.width, buttonsY, AlertViewWidth/2, 44);
            [self.alertView addSubview:_otherButton];
            
            CALayer *lineLayer = [CALayer layer];
            lineLayer.backgroundColor = [[UIColor colorWithWhite:0.90 alpha:0.3] CGColor];
            lineLayer.frame = CGRectMake(_otherButton.frame.origin.x, _otherButton.frame.origin.y, 0.5, AlertViewButtonHeight);
            [_alertView.layer addSublayer:lineLayer];
            
        } else {
            _cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
            _cancelButton.frame = CGRectMake(0, buttonsY, AlertViewWidth, AlertViewButtonHeight);
        }
        
        [_alertView addSubview:_cancelButton];
        
        _alertView.bounds = CGRectMake(0, 0, AlertViewWidth, 150);
        _alertView.center = CGPointMake(CGRectGetMidX(keyWindow.bounds), CGRectGetMidY(keyWindow.bounds));
        
        _completion = completion;
        
        [self setupGestures];
        
        [self resizeViews];
    }
    return self;
}

- (void)show
{
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow addSubview:self];
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        keyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        [keyWindow tintColorDidChange];
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        self.backgroundView.alpha = 1;
    }];
    
    [self showAlertAnimation];
}

- (void)dismiss:(id)sender
{
    [self dismissAlertAnimation];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.backgroundView.alpha = 0;
        self.alertView.alpha = 0;
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
            UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
            keyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            [keyWindow tintColorDidChange];
        }
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        
        BOOL cancelled;
        if (sender == self.cancelButton || sender == self.tap) {
            cancelled = YES;
        } else {
            cancelled = NO;
        }
        self.completion(cancelled);
    }];
}

- (void)setBackgroundColorForButton:(id)sender
{
    [sender setBackgroundColor:[UIColor colorWithRed:94/255.0 green:196/255.0 blue:221/255.0 alpha:1.0]];
}

- (void)clearBackgroundColorForButton:(id)sender
{
    [sender setBackgroundColor:[UIColor clearColor]];
}

#pragma mark - public

+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
               cancelTitle:(NSString *)cancelTitle
                otherTitle:(NSString *)otherTitle
                completion:(void(^) (BOOL cancelled))completion
{
    PXAlertView *alertView = [[PXAlertView alloc] initAlertWithTitle:title
                                                             message:message
                                                         cancelTitle:cancelTitle
                                                          otherTitle:otherTitle
                                                          completion:completion];
    [alertView show];
}

#pragma mark - gestures

- (void)setupGestures
{
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
    [self.tap setNumberOfTapsRequired:1];
    [self.backgroundView setUserInteractionEnabled:YES];
    [self.backgroundView setMultipleTouchEnabled:NO];
    [self.backgroundView addGestureRecognizer:self.tap];
}

#pragma mark -

- (CGRect)adjustLabelFrameHeight:(UILabel *)label
{
    CGSize size = [label.text sizeWithFont:label.font constrainedToSize:CGSizeMake(label.frame.size.width, FLT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
    return CGRectMake(label.frame.origin.x, label.frame.origin.y, label.frame.size.width, size.height);
}

- (void)resizeViews
{
    CGFloat totalHeight = 0;
    for (UIView *view in [self.alertView subviews]) {
        if ([view class] != [UIButton class]) {
            totalHeight += view.frame.size.height + AlertViewVerticalElementSpace;
        }
    }
    totalHeight += AlertViewButtonHeight;
    totalHeight += AlertViewVerticalElementSpace;
    
    self.alertView.frame = CGRectMake(self.alertView.frame.origin.x,
                                      self.alertView.frame.origin.y,
                                      self.alertView.frame.size.width,
                                      totalHeight);
}

- (void)showAlertAnimation
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    animation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.05, 1.05, 1)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)]];
    animation.keyTimes = @[ @0, @0.5, @1 ];
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = .2;
    
    [self.alertView.layer addAnimation:animation forKey:@"showAlert"];
}

- (void)dismissAlertAnimation
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    animation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.95, 0.95, 1)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8, 0.8, 1)]];
    animation.keyTimes = @[ @0, @0.5, @1 ];
    animation.fillMode = kCAFillModeRemoved;
    animation.duration = .2;
    
    [self.alertView.layer addAnimation:animation forKey:@"dismissAlert"];
}

@end