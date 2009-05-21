// 
// Classes
// UICBadgeView.m
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

#import "UICBadgeView.h"

CGGradientRef badgeGrowGradientColor = nil;

@implementation UICBadgeView

@dynamic text, fontSize;
@synthesize horizontalCenter, verticalTop;

#pragma mark -
#pragma mark Class method

+ (void)initialize {
	if (badgeGrowGradientColor == nil) {
		// Make CGGradientRef to fill with graduation color
		// For glowing
		CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
		CGFloat colors[] = {
			1.0, 1.0, 1.0, 0.9,
			1.0, 1.0, 1.0, 0.0
		};
		badgeGrowGradientColor = CGGradientCreateWithColorComponents( rgb, colors, NULL, sizeof(colors)/(sizeof(colors[0])*4) );
		CGColorSpaceRelease(rgb);
	}
}

#pragma mark -
#pragma mark Setter, Accessor

- (void)setFontSize:(float)newValue {
	// update with new size font
	[numFont release];
	numFont = [[UIFont boldSystemFontOfSize:newValue] retain];
	
	// reload all contents layout information
	[self updateBadge];
}

- (void)setHorizontalCenter:(float)newValue {
	horizontalCenter = newValue;
	
	// reload all contents layout information
	[self updateBadge];
}

- (void)setVerticalTop:(float)newValue {
	verticalTop = newValue;
	
	// reload all contents layout information
	[self updateBadge];
}

- (float)fontSize {
	return [numFont pointSize];
}

- (void)setText:(NSString*)newValue {
	// update text content
	if (newValue != text) {
		[text release];
		text = [newValue retain];
		[self updateBadge];
		[self setNeedsDisplay];
	}
}

- (NSString*)text {
	return text;
}

#pragma mark -
#pragma mark Set text with number of remained items.

- (void)setRemainedNumber:(int)newValue {
	// update number drawn on badge
	// typically use for number of remained items 
	if( newValue == 0 ) {
		[text release];
		text = nil;
		self.hidden = YES;
	}
	else {
		[text release];
		text = [[NSString stringWithFormat:@"%d", newValue] retain];
		[self updateBadge];
		[self setNeedsDisplay];
		self.hidden = NO;
	}
}

- (void)setupLayoutInformation {
	badgeType = UICFreeBadge;
	// default
	[numFont release];
	numFont = [[UIFont boldSystemFontOfSize:20] retain];
	numy = 0;
	sx = 10;
	sy = 10;
	t = 5;
	text_offset_x = 0;
	text_offset_y = 0;
	badgeBorderWidth = 2;
}

#pragma mark -
#pragma mark Original

- (id)initWithBadgeStyle:(UICBadgeType)type {
	DNSLogMethod
	if (self = [super init]) {
		// setup basic settings
		self.backgroundColor = [UIColor clearColor];
		[self setupLayoutInformation];
		badgeType = type;
		
		// setup for particular badge type
		if (badgeType == UICTabbarBadge) {
			// mini badge
			[numFont release];
			numFont = [[UIFont boldSystemFontOfSize:11] retain];
			numy = 1.0;
			text_offset_x = 0.5;
		}
		else if (badgeType == UICSpringboardBadge) {
			// spring board badge
			[numFont release];
			numFont = [[UIFont boldSystemFontOfSize:16] retain];
			numy = 0.5;
			text_offset_y = -0.5;
		}
		[self updateBadge];
    }
    return self;
}

#pragma mark -
#pragma mark Make Quartz path to draw

- (void)makePathCircleCornerRect:(CGRect)rect radius:(float)radius {
    CGContextRef context = UIGraphicsGetCurrentContext();
	
    // get points
    CGFloat minx = CGRectGetMinX( rect ), midx = CGRectGetMidX( rect ), maxx = CGRectGetMaxX( rect );
    CGFloat miny = CGRectGetMinY( rect ), midy = CGRectGetMidY( rect ), maxy = CGRectGetMaxY( rect );
    
    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
    CGContextAddLineToPoint(context, minx, midy);
}

- (void)makePathCircleCornerRectForglow:(CGRect)rect glowSize:(CGSize)glowSize glowRadius:(float)glowRadius {	
	float grx = rect.origin.x + (rect.size.width  - glowSize.width) * 0.5 - glowRadius;
	float gry = rect.origin.y + glowSize.height - glowRadius * 2;
	float grw = glowSize.width + 2 * glowRadius;
	float grh = glowRadius * 2;
	
	[self makePathCircleCornerRect:CGRectMake(grx, gry, grw, grh) radius:glowRadius];
}

#pragma mark -
#pragma mark Update layout information

- (void)updateBadge {
	DNSLogMethod
	
	// get size typical character, 1
	NSString* dummyString = @"1";
	CGSize baseNSize = [dummyString sizeWithFont:numFont];
	
	// invaliables
	CGSize n = [text sizeWithFont:numFont];
	float nw = n.width;
	float nh = n.height;

	// text left margin
	float numx = numy - (baseNSize.width - baseNSize.height) * 0.5;
	
	// round corner area's radius
	float r = nh * 0.5 + numy;
	
	// width of round corner area's width subtracted with above radius.
	float itx = 2 * (nw * 0.5 - ( r - numx));
	
	// badge origin
	float bx = sx;
	float by = t;
	
	// text box origin
	float tx = sx + numx;
	float ty = t + numy;
	
	// view's size
	float aw = 2 * r + 2 * sx + itx;
	float ah = 2 * r + t + sy;
	
	// badge size
	float bw = aw - 2 * sx;
	float bh = ah - t - sy;
	
	// auto or invalble border width
	if (badgeType == UICFreeBadge) {
		badgeBorderWidth = (3.0 * [numFont pointSize] + 40.0f) / 70.0f;
	}

	// update valiables
	regionToDraw = CGRectMake(bx, by, bw, bh);
	textDrawPoint = CGPointMake(tx+text_offset_x, ty+text_offset_y);
	defaultRadius = r;
	self.frame = CGRectMake(horizontalCenter - (int)(aw/2), verticalTop - t, aw, ah);
}

#pragma mark -
#pragma mark Override

- (id)init {
	if (self = [super init]) {
		self.backgroundColor = [UIColor clearColor];
		[self setupLayoutInformation];
		[self updateBadge];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// draw main badge with shadow
	CGContextSaveGState(context);
	[self makePathCircleCornerRect:regionToDraw radius:defaultRadius];
	CGContextSetShadowWithColor(context, CGSizeMake(0, -4), 3, [UIColor colorWithRed:0 green:0 blue:0 alpha:0.85].CGColor);
	CGContextSetRGBFillColor(context, 218.0/255.0, 8.0/255.0, 18.0/255.0, 1.0);
	CGContextFillPath(context);
	CGContextRestoreGState(context);
	
	// draw main badge's border
	CGContextSaveGState(context);
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	CGContextSetLineWidth(context, badgeBorderWidth);
	[self makePathCircleCornerRect:regionToDraw radius:defaultRadius];
	CGContextStrokePath(context);
	CGContextRestoreGState(context);

	// draw text
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
	[text drawAtPoint:textDrawPoint withFont:numFont];
	
	// draw glow
	CGContextSaveGState(context);
	[self makePathCircleCornerRect:regionToDraw radius:defaultRadius];
	CGContextClip(context);
	[self makePathCircleCornerRectForglow:regionToDraw glowSize:CGSizeMake((regionToDraw.size.width - defaultRadius * 2) * 0.8, regionToDraw.size.height *0.5) glowRadius:defaultRadius*2];
	CGContextEOClip(context);
	CGContextDrawLinearGradient(context, badgeGrowGradientColor, CGPointMake(regionToDraw.origin.x, regionToDraw.origin.y),
								CGPointMake(regionToDraw.origin.x, regionToDraw.origin.y+regionToDraw.size.height*0.6),
								kCGGradientDrawsBeforeStartLocation);
	CGContextRestoreGState(context);
	
}

#pragma mark -
#pragma mark dealloc

- (void)dealloc {
	[numFont release];
    [super dealloc];
}

@end
