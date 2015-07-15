// MessageComposerView.h
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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
alpha:1.0]

@protocol MessageComposerViewDelegate <NSObject>
// delegate method executed after the user clicks the send button. Message is the message contained within the
// text view when send is pressed
- (void)messageComposerSendMessageClickedWithMessage:(NSString*)message;
@optional
// delagate method executed after the user clicks the camera button
- (void)messageComposerCameraButtonClicked;
// executed whenever the MessageComposerView's frame changes. Provides the frame it is changing to and the animation duration
- (void)messageComposerFrameDidChange:(CGRect)frame withAnimationDuration:(CGFloat)duration;
// executed whenever the user is typing in the text view
- (void)messageComposerUserTyping;

@optional
-(void)messageComposerDidEndEditing;
@optional
-(void)messageComposerDidBeginEditing;

@end

@interface MessageComposerView : UIView<UITextViewDelegate>
@property(nonatomic, weak) id<MessageComposerViewDelegate> delegate;
@property(nonatomic, readonly) CGFloat originalFrameHeight;
@property(nonatomic) NSInteger keyboardOffset;
@property(nonatomic, strong) UITextView* messageTextView;

- (id)initWithKeyboardOffset:(NSInteger)offset andMaxHeight:(CGFloat)maxTVHeight andTextView:(UITextView*)textView;
// init with screen width and default height. Offset provided is space between composer and keyboard/bottom of screen
- (id)initWithKeyboardOffset:(NSInteger)offset andMaxHeight:(CGFloat)maxTVHeight;
// init with provided frame and offset between composer and keyboard/bottom of screen
- (id)initWithFrame:(CGRect)frame andKeyboardOffset:(NSInteger)offset;
// init with provided frame and offset between composer and keyboard/bottom of screen. Also set a max height on composer.
- (id)initWithFrame:(CGRect)frame andKeyboardOffset:(NSInteger)offset andMaxHeight:(CGFloat)maxTVHeight andTextView:(UITextView*)textView;
// provide a function to scroll the textview to bottom manually in fringe cases like loading message drafts etc.
- (void)scrollTextViewToBottom;

// To avoid exposing the UITextView and attempt to prevent bad practice, startEditing and finishEditing
// are available to become and resign first responder. This means you shouldn't have an excuse to
// do [messageComposerView.messageTextView resignFirstResponder] etc.
- (void)startEditing;
- (void)finishEditing;

// hide/show camera button
- (void)hideCameraButton;
- (void)showCameraButton;

// Set send button color
-(void)setSendButtonColor:(UIColor*)color;

// Set border color
-(void)setBorderColor:(UIColor*)color;

// Set the text in the textview
-(void)setTextViewText:(NSString*)text;
@end
