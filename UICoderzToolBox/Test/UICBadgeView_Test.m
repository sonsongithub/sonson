// 
// Classes
// UICBadgeView_Test.m
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

#import "UICBadgeView_Test.h"

@implementation UICBadgeView_Test

+ (void)test:(id)object {
	UINavigationController* nav = (UINavigationController*)object;
	UICBadgeView_Test *con = [[UICBadgeView_Test alloc] init];
	[nav pushViewController:con animated:YES];
	[con release];
}

- (id)init {
	self = [super initWithNibName:@"UICBadgeView_Test" bundle:nil];
	return self;
}

- (void)viewDidLoad {
	DNSLogMethod
    [super viewDidLoad];
	slider.minimumValue = 0;
	slider.maximumValue = 100;
	[slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
	
	springboardBadge = [[UICBadgeView alloc] init];
	tabbarBadge = [[UICBadgeView alloc] init];
	freestyleBadge = [[UICBadgeView alloc] init];
	
	springboardBadge = [[UICBadgeView alloc] initWithBadgeStyle:UICSpringboardBadge];
	[springboardBadge setRemainedNumber:2];
	springboardBadge.horizontalCenter = 257;
	springboardBadge.verticalTop = 97;
	[self.view addSubview:springboardBadge];
	
	tabbarBadge = [[UICBadgeView alloc] initWithBadgeStyle:UICTabbarBadge];
	[tabbarBadge setRemainedNumber:2];
	tabbarBadge.horizontalCenter = 106 + 145;
	tabbarBadge.verticalTop = 211;
	[self.view addSubview:tabbarBadge];
	
	freestyleBadge = [[UICBadgeView alloc] initWithBadgeStyle:UICFreeBadge];
	freestyleBadge.fontSize = 80;
	[freestyleBadge setRemainedNumber:2];
	freestyleBadge.horizontalCenter = 160;
	freestyleBadge.verticalTop = 280;
	freestyleBadge.frame = CGRectMake(80, 270 ,freestyleBadge.frame.size.width, freestyleBadge.frame.size.height);
	[self.view addSubview:freestyleBadge];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	DNSLogMethod
	[textField resignFirstResponder];
	
	springboardBadge.text = textField.text;
	tabbarBadge.text = textField.text;
	freestyleBadge.text = textField.text;
	return NO;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (void)sliderAction:(id)sender {
	[springboardBadge setRemainedNumber:slider.value];
	[tabbarBadge setRemainedNumber:slider.value];
	[freestyleBadge setRemainedNumber:slider.value];
}

- (void)dealloc {
    [super dealloc];
}

@end
