// MessageComposerView.m
//
// Copyright (c) 2015 oseparovic. ( http://thegameengine.org )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MessageComposerView.h"
#import <QuartzCore/QuartzCore.h>

@interface MessageComposerView()
- (IBAction)sendClicked:(id)sender;
- (IBAction)cameraClicked:(id)sender;
@property(nonatomic, strong) UIButton *sendButton;
@property(nonatomic, strong) UIButton *cameraButton;
@property(nonatomic) CGFloat keyboardHeight;
@property(nonatomic) CGFloat keyboardAnimationDuration;
@property(nonatomic) NSInteger keyboardAnimationCurve;
@property(nonatomic) UIEdgeInsets composerBackgroundInsets;
@property(nonatomic) CGFloat composerTVMaxHeight;
@property(nonatomic, readwrite) CGFloat originalFrameHeight;
@property(nonatomic, strong) UILabel *placeholderLabel;
@property(nonatomic) CALayer *topBorder;

@end

@implementation MessageComposerView

const NSInteger defaultHeight = 48;

- (id)init {
    return [self initWithKeyboardOffset:0 andMaxHeight:CGFLOAT_MAX];
}

- (id)initWithKeyboardOffset:(NSInteger)offset andMaxHeight:(CGFloat)maxTVHeight andTextView:(UITextView*)textView {
    return [self initWithFrame:CGRectMake(0, [self currentScreenSize].height-defaultHeight,[self currentScreenSize].width,defaultHeight) andKeyboardOffset:offset andMaxHeight:maxTVHeight andTextView:textView];
}

- (id)initWithKeyboardOffset:(NSInteger)offset andMaxHeight:(CGFloat)maxTVHeight {
    return [self initWithFrame:CGRectMake(0, [self currentScreenSize].height-defaultHeight,[self currentScreenSize].width,defaultHeight) andKeyboardOffset:offset andMaxHeight:maxTVHeight andTextView:nil];
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame andKeyboardOffset:0];
}

- (id)initWithFrame:(CGRect)frame andKeyboardOffset:(NSInteger)offset {
    return [self initWithFrame:frame andKeyboardOffset:offset andMaxHeight:CGFLOAT_MAX andTextView:nil];
}

- (id)initWithFrame:(CGRect)frame andKeyboardOffset:(NSInteger)offset andMaxHeight:(CGFloat)maxTVHeight andTextView:(UITextView*)textView {
    self = [super initWithFrame:frame];
    if (self) {
        // top inset is used as a minimum value of top padding.
        _composerBackgroundInsets = UIEdgeInsetsMake(8, 7, 8, 7);

        // Default animation time for 5 <= iOS <= 7. Should be overwritten by first keyboard notification.
        _keyboardAnimationDuration = 0.25;
        _keyboardAnimationCurve = 7;
        _keyboardOffset = offset;
        _composerBackgroundInsets.top = MAX(_composerBackgroundInsets.top, frame.size.height - _composerBackgroundInsets.bottom - 34);
        _composerTVMaxHeight = maxTVHeight;

        // alloc necessary elements
        self.sendButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [self.sendButton addTarget:self action:@selector(sendClicked:) forControlEvents:UIControlEventTouchUpInside];
        self.placeholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];

        self.cameraButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [self.cameraButton addTarget:self action:@selector(cameraClicked:) forControlEvents:UIControlEventTouchUpInside];

        // fix ridiculous jumpy scrolling bug inherant in native UITextView since 7.0
        // http://stackoverflow.com/a/19339716/740474
        NSString *reqSysVer = @"7.0";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        BOOL osVersionSupported = ([currSysVer compare:reqSysVer  options:NSNumericSearch] != NSOrderedAscending);
        if (osVersionSupported)  {
            NSTextStorage* textStorage = [[NSTextStorage alloc] init];
            NSLayoutManager* layoutManager = [NSLayoutManager new];
            [textStorage addLayoutManager:layoutManager];
            NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:self.bounds.size];
            [layoutManager addTextContainer:textContainer];
            self.messageTextView = [[UITextView alloc] initWithFrame:CGRectZero textContainer:textContainer];
        } else {
            self.messageTextView = [[UITextView alloc] initWithFrame:CGRectZero];
        }

        if (textView != nil ) {
            self.messageTextView = textView;
        }

        self.messageTextView.returnKeyType = UIReturnKeySend;

        // configure elements
        [self setup];

        // insert elements above MessageComposerView
        [self insertSubview:self.sendButton aboveSubview:self];
        [self insertSubview:self.messageTextView aboveSubview:self];
        [self insertSubview:self.cameraButton aboveSubview:self];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)hideCameraButton {
    self.cameraButton.hidden = YES;

    CGRect newTextViewFrame = self.messageTextView.frame;
    newTextViewFrame.size.width = newTextViewFrame.size.width + self.cameraButton.frame.size.width;
    newTextViewFrame.origin.x = newTextViewFrame.origin.x - self.cameraButton.frame.size.width - _composerBackgroundInsets.left;
    self.messageTextView.frame = newTextViewFrame;
    self.originalFrameHeight = self.frame.size.height;
}

-(void)showCameraButton {
    CGRect newTextViewFrame = self.messageTextView.frame;
    newTextViewFrame.size.width = newTextViewFrame.size.width - self.cameraButton.frame.size.width;
    newTextViewFrame.origin.x = newTextViewFrame.origin.x + self.cameraButton.frame.size.width + _composerBackgroundInsets.left;
    self.messageTextView.frame = newTextViewFrame;
    self.originalFrameHeight = self.frame.size.height;

    self.cameraButton.hidden = NO;
}

-(void)setTextViewText:(NSString*)text {
    [self.messageTextView setText:text];
    // Manually trigger the textViewDidChange method as setting the text when the messageTextView is not first responder the
    // UITextViewTextDidChangeNotification notification does not get fired.
    [self textViewDidChange:self.messageTextView];
}

-(void)setSendButtonColor:(UIColor*)color {
    [self.sendButton setTitleColor: color forState:UIControlStateNormal];
}

-(void)setBorderColor:(UIColor*)color {
    CGSize mainViewSize = self.bounds.size;
    CGFloat borderWidth = 0.8f;
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, mainViewSize.width, borderWidth)];
    topView.opaque = YES;
    topView.backgroundColor = color;
    topView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:topView];
}

- (void)setup {
    self.backgroundColor =  [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];
    self.autoresizesSubviews = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.userInteractionEnabled = YES;
    self.multipleTouchEnabled = NO;

    self.layer.borderWidth = 0;
    [self setBorderColor:[UIColor lightGrayColor]];

    CGRect sendButtonFrame = self.bounds;
    sendButtonFrame.size.width = 50;
    sendButtonFrame.size.height = defaultHeight - _composerBackgroundInsets.top - _composerBackgroundInsets.bottom;
    sendButtonFrame.origin.x = self.frame.size.width - _composerBackgroundInsets.right - sendButtonFrame.size.width;
    sendButtonFrame.origin.y = self.bounds.size.height - _composerBackgroundInsets.bottom - sendButtonFrame.size.height;
    [self.sendButton setFrame:sendButtonFrame];
    [self.sendButton setAutoresizingMask:(UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin)];
    [self.sendButton.layer setCornerRadius:5];
    [self.sendButton setTitleColor: [UIColor colorWithRed:0/255.0f green:118/255.0f blue:255/255.0f alpha:1.0f] forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor colorWithRed:210/255.0 green:210/255.0 blue:210/255.0 alpha:1.0] forState:UIControlStateHighlighted];
    [self.sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    [self.sendButton setBackgroundColor: [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f]];
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [self.sendButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];

    CGRect messageTextViewFrame = self.bounds;
    messageTextViewFrame.origin.x = _composerBackgroundInsets.left + 45;
    messageTextViewFrame.origin.y = _composerBackgroundInsets.top;
    messageTextViewFrame.size.width = self.frame.size.width - _composerBackgroundInsets.left - 55 - sendButtonFrame.size.width - _composerBackgroundInsets.right;
    messageTextViewFrame.size.height = defaultHeight - _composerBackgroundInsets.top - _composerBackgroundInsets.bottom;

    [self.messageTextView setFrame:messageTextViewFrame];
    [self.messageTextView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin)];
    [self.messageTextView setShowsHorizontalScrollIndicator:NO];
    [self.messageTextView.layer setCornerRadius:5];
    [self.messageTextView setFont:[UIFont systemFontOfSize:14]];
    [self.messageTextView setDelegate:self];
    [self.messageTextView.layer setBorderColor:[UIColor colorWithRed:215/255.0f green:215/255.0f blue:215/255.0f alpha:1.0f].CGColor];
    [self.messageTextView.layer setBorderWidth:1.0f];
    [self.messageTextView setKeyboardType:UIKeyboardTypeTwitter];

    [self.placeholderLabel setText: @"Tap to reply"];
    [self.placeholderLabel setFont: [UIFont italicSystemFontOfSize: 14]];
    [self.placeholderLabel setTextColor:[UIColor colorWithWhite: 0.70 alpha:1]];
    [self.placeholderLabel sizeToFit];
    [self.messageTextView addSubview: self.placeholderLabel];
    CGRect myFrame = self.placeholderLabel.frame;
    myFrame.origin = CGPointMake(9, 8);
    self.placeholderLabel.frame = myFrame;

    CGRect cameraButtonFrame = self.bounds;
    cameraButtonFrame.size.width = 30;
    cameraButtonFrame.size.height = 22;
    cameraButtonFrame.origin.x = _composerBackgroundInsets.right + 2;
    cameraButtonFrame.origin.y = self.bounds.size.height - _composerBackgroundInsets.bottom - cameraButtonFrame.size.height - 7;
    [self.cameraButton setFrame:cameraButtonFrame];
    [self.cameraButton setAutoresizingMask:(UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin)];
    [self.cameraButton setImage:[UIImage imageNamed:@"MessageComposerView.bundle/images/cameraIcon.png"] forState:UIControlStateNormal];

    self.originalFrameHeight = self.frame.size.height;

    NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)layoutSubviews {
    // Due to inconsistent handling of rotation when receiving UIDeviceOrientationDidChange notifications
    // ( see http://stackoverflow.com/q/19974246/740474 ) rotation handling and view resizing is done here.
    CGFloat oldHeight = self.messageTextView.frame.size.height;
    CGFloat newHeight = [self sizeWithText:self.messageTextView.text];

    if (newHeight >= _composerTVMaxHeight) {
        [self scrollTextViewToBottom];
    }
    if (oldHeight == newHeight) {
        // In cases where the height remains the same after the text change/rotation only change the y origin
        CGRect frame = self.frame;
        frame.origin.y = ([self currentScreenSize].height - [self currentKeyboardHeight]) - frame.size.height - _keyboardOffset;
        self.frame = frame;

        // Even though the height didn't change the origin did so notify delegates
        if ([self.delegate respondsToSelector:@selector(messageComposerFrameDidChange:withAnimationDuration:)]) {
            [self.delegate messageComposerFrameDidChange:frame withAnimationDuration:0];
        }
    } else {
        // The view is already animating as part of the rotation so we just have to make sure it
        // snaps to the right place and resizes the textView to wrap the text with the new width. Changing
        // to add an additional animation will overload the animation and make it look like someone is
        // shuffling a deck of cards.
        // Recalculate MessageComposerView container frame
        CGRect newContainerFrame = self.frame;
        newContainerFrame.size.height = newHeight + _composerBackgroundInsets.top + _composerBackgroundInsets.bottom;
        newContainerFrame.origin.y = ([self currentScreenSize].height - [self currentKeyboardHeight]) - newContainerFrame.size.height - _keyboardOffset;;

        // Recalculate send button frame
        CGRect newSendButtonFrame = self.sendButton.frame;
        newSendButtonFrame.origin.y = newContainerFrame.size.height - (_composerBackgroundInsets.bottom + newSendButtonFrame.size.height);

        CGRect newCameraButtonFrame = self.cameraButton.frame;
        newCameraButtonFrame.origin.y = newContainerFrame.size.height - (_composerBackgroundInsets.bottom + newCameraButtonFrame.size.height + 6);

        // Recalculate UITextView frame
        CGRect newTextViewFrame = self.messageTextView.frame;
        newTextViewFrame.size.height = newHeight;
        //newTextViewFrame.origin.y = _composerBackgroundInsets.top;

        self.frame = newContainerFrame;
        self.sendButton.frame = newSendButtonFrame;
        self.messageTextView.frame = newTextViewFrame;
        self.cameraButton.frame = newCameraButtonFrame;

        [self scrollTextViewToBottom];

        if ([self.delegate respondsToSelector:@selector(messageComposerFrameDidChange:withAnimationDuration:)]) {
            [self.delegate messageComposerFrameDidChange:newContainerFrame withAnimationDuration:0];
        }
    }
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text  isEqual: @"\n"]) {
        if ([self.messageTextView.text length] <= 200) {

            
            NSString *text = self.messageTextView.text;
            [self.messageTextView setText:@""];

            if ([self.delegate respondsToSelector:@selector (messageComposerSendMessageClickedWithMessage:)]) {
                [self.delegate messageComposerSendMessageClickedWithMessage:text];
            }

            // Manually trigger the textViewDidChange method as setting the     text when the messageTextView is not first responder the
            // UITextViewTextDidChangeNotification notification does not get fired.
            [self textViewDidChange:self.messageTextView];
        }

        return false;
    }

    return  textView.text.length + (text.length - range.length) <= 200;
}


#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    [self setNeedsLayout];

    if ([self.delegate respondsToSelector:@selector(messageComposerUserTyping)])
        [self.delegate messageComposerUserTyping];
}

- (void)textViewDidBeginEditing:(UITextView*)textView {

    if ([self.delegate respondsToSelector:@selector(messageComposerDidBeginEditing)]) {
        [self.delegate messageComposerDidBeginEditing];
    }

    CGRect frame = self.frame;
    frame.origin.y = ([self currentScreenSize].height - [self currentKeyboardHeight]) - frame.size.height - _keyboardOffset;

    [UIView animateWithDuration:_keyboardAnimationDuration
                          delay:0.0
                        options:(_keyboardAnimationCurve << 16)
                     animations:^{self.frame = frame;}
                     completion:nil];

    if ([self.delegate respondsToSelector:@selector(messageComposerFrameDidChange:withAnimationDuration:)]) {
        [self.delegate messageComposerFrameDidChange:frame withAnimationDuration:_keyboardAnimationDuration];
    }

    self.placeholderLabel.hidden = true;
}

- (void)textViewDidEndEditing:(UITextView*)textView {

    if ([self.delegate respondsToSelector:@selector(messageComposerDidEndEditing)]) {
        [self.delegate messageComposerDidEndEditing];
    }

    CGRect frame = self.frame;
    frame.origin.y = [self currentScreenSize].height - self.frame.size.height - _keyboardOffset;

    [UIView animateWithDuration:_keyboardAnimationDuration
                          delay:0.0
                        options:(_keyboardAnimationCurve << 16)
                     animations:^{self.frame = frame;}
                     completion:nil];

    if ([self.delegate respondsToSelector:@selector(messageComposerFrameDidChange:withAnimationDuration:)]) {
        [self.delegate messageComposerFrameDidChange:frame withAnimationDuration:_keyboardAnimationDuration];
    }

    self.placeholderLabel.hidden = false;
}


#pragma mark - Keyboard Notifications
- (void)keyboardWillShow:(NSNotification*)notification {
    // Because keyboard animation time and cure vary by iOS version, and we don't want to build the library
    // on top of spammy keyboard notifications we use UIKeyboardWillShowNotification ONLY to dynamically set our
    // animation duration. As a UIKeyboardWillShowNotification is fired BEFORE textViewDidBeginEditing
    // is triggered we can use the following values for all of animations including the first.
    _keyboardAnimationDuration = [[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] floatValue];
    _keyboardAnimationCurve = [[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] intValue];
}

#pragma mark - Keyboard Notifications
- (void)keyboardWillHide:(NSNotification*)notification {
    self.keyboardHeight = 0;
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    CGRect rect = [[notification userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect converted = [self convertRect:rect fromView:nil];
    self.keyboardHeight = converted.size.height;
    [self setNeedsLayout];
}


#pragma mark - IBAction
- (IBAction)sendClicked:(id)sender {

    NSString *keyboardText = self.messageTextView.text;
    [self.messageTextView setText:@""];

    if ([self.delegate respondsToSelector:@selector(messageComposerSendMessageClickedWithMessage:)]) {
        [self.delegate messageComposerSendMessageClickedWithMessage:keyboardText];
    }

    // Manually trigger the textViewDidChange method as setting the text when the messageTextView is not first responder the
    // UITextViewTextDidChangeNotification notification does not get fired.
    [self textViewDidChange:self.messageTextView];
}

#pragma mark - IBAction
- (IBAction)cameraClicked:(id)sender {
    if ([self.delegate respondsToSelector:@selector(messageComposerCameraButtonClicked)])
        [self.delegate messageComposerCameraButtonClicked];
}


#pragma mark - Utils
- (void)scrollTextViewToBottom {
    // scrollRangeToVisible:NSMakeRange is a pretty buggy function. Manually setting the content offset seems to work better
    CGPoint offset = CGPointMake(0, self.messageTextView.contentSize.height - self.messageTextView.frame.size.height);
    [self.messageTextView setContentOffset:offset animated:NO];
}

- (float)currentKeyboardHeight {
    if ([self.messageTextView isFirstResponder]) {
        return self.keyboardHeight;
    } else {
        return 0;
    }
}

- (CGFloat)sizeWithText:(NSString*)text {
    CGFloat fixedWidth = self.messageTextView.frame.size.width;
    CGSize newSize = [self.messageTextView sizeThatFits:CGSizeMake(fixedWidth, CGFLOAT_MAX)];
    return MIN(_composerTVMaxHeight, newSize.height);
}

- (void)startEditing {
    [self.messageTextView becomeFirstResponder];
}

- (void)finishEditing {
    [self.messageTextView resignFirstResponder];
}


#pragma mark - Screen Size Computation
- (CGSize)currentScreenSize {
    // return the screen size with respect to the orientation
    return [self currentScreenSizeInInterfaceOrientation:[self currentInterfaceOrientation]];
}

- (CGSize)currentScreenSizeInInterfaceOrientation:(UIInterfaceOrientation)orientation {
    // http://stackoverflow.com/a/7905540/740474
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIApplication *application = [UIApplication sharedApplication];

    // if the orientation at this point is landscape but it hasn't fully rotated yet use landscape size instead.
    // handling differs between iOS 7 && 8 so need to check if size is properly configured or not. On
    // iOS 7 height will still be greater than width in landscape without this call but on iOS 8
    // it won't
    if (UIInterfaceOrientationIsLandscape(orientation) && size.height > size.width) {
        size = CGSizeMake(size.height, size.width);
    }

    // subtract the status bar height if visible
    if (application.statusBarHidden == NO && !([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)) {
        // if the status bar is not hidden subtract its height from the screensize.
        // NOTE: as of iOS 7 the status bar overlaps the application rather than sits on top of it, so hidden or not
        // its height is irrelevant in our position calculations.
        // see http://blog.jaredsinclair.com/post/61507315630/wrestling-with-status-bars-and-navigation-bars-on-ios-7
        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    }

    return size;
}

- (UIInterfaceOrientation)currentInterfaceOrientation {
    // Returns the orientation of the Interface NOT the Device. The two do not happen in exact unison so
    // this point is important.
    return [UIApplication sharedApplication].statusBarOrientation;
}

@end

