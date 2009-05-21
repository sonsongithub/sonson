// 
// Classes
// UICBadgeView.h
// 
// The MIT License
// 
// Copyright (c) 2009 sonson, sonson@Picture&Software
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
//
//  Created by sonson on 08/12/28.
//  Copyright 2008 sonson, sonson@Picture&Software. All rights reserved.
//

#import <UIKit/UIKit.h>

// badge type identifier

typedef enum {
	UICSpringboardBadge = 0,	// badge of Springboard's application icon.
	UICTabbarBadge		= 1,	// badge of UITabbar
	UICFreeBadge		= 2,	// free style badge
}UICBadgeType;

// class

@interface UICBadgeView : UIView {
	// badge type with UICBadgeType
	UICBadgeType	badgeType;
	
	// font of text inside badge
	UIFont			*numFont;
	
	// content drawn inside badge
	NSString		*text;
	
	// size and position of badge's elements
	float			defaultRadius;
	float			numy;
	float			sx;
	float			sy;
	float			t;
	float			text_offset_x;
	float			text_offset_y;
	float			badgeBorderWidth;
	
	//
	float			horizontalCenter;
	float			verticalTop;

	// arrange above valiables into rect and point to drawRect
	CGRect			regionToDraw;
	CGPoint			textDrawPoint;
}
@property(nonatomic, assign) float fontSize;
@property(nonatomic, retain) NSString* text;

@property(nonatomic, assign) float horizontalCenter;
@property(nonatomic, assign) float verticalTop;

#pragma mark -
#pragma mark Class method
+ (void)initialize;
#pragma mark -
#pragma mark Setter, Accessor
- (void)setFontSize:(float)newValue;
- (float)fontSize;
- (void)setText:(NSString*)newValue;
- (NSString*)text;
#pragma mark -
#pragma mark Set text with number of remained items.
- (void)setRemainedNumber:(int)newValue;
- (void)setupLayoutInformation;
#pragma mark -
#pragma mark Original
- (id)initWithBadgeStyle:(UICBadgeType)type;
#pragma mark -
#pragma mark Make Quartz path to draw
- (void)makePathCircleCornerRect:(CGRect)rect radius:(float)radius;
- (void)makePathCircleCornerRectForglow:(CGRect)rect glowSize:(CGSize)glowSize glowRadius:(float)glowRadius;
#pragma mark -
#pragma mark Update layout information
- (void)updateBadge;

@end
