//
//  UICTestSelectViewController.m
//  UICoderzToolBox
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

#import "UICTestSelectViewController.h"

// Test class
#import "UICBadgeView_Test.h"
#import "UICNSData+AES256_Test.h"

@implementation UICTestSelectViewController

#pragma mark -
#pragma mark UITableViewDelegate, UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *kCellID = @"cellUICTestSelectView";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID] autorelease];
	}
	Class aClass = [testClasses objectAtIndex:indexPath.row];
	cell.textLabel.text = [NSString stringWithCString:class_getName([aClass class])];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	Class aClass = [testClasses objectAtIndex:indexPath.row];
	[aClass test:self.navigationController];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [testClasses count];
}

#pragma mark -
#pragma mark Override

- (id)init {
	DNSLogMethod
	self = [super initWithNibName:nil bundle:nil];

	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 416) style:UITableViewStylePlain];
	[self.view addSubview:tableView];
	
	tableView.delegate = self;
	tableView.dataSource = self;
	
	testClasses = [[NSMutableArray array] retain];
	[testClasses addObject:[UICBadgeView_Test class]];
	[testClasses addObject:[UICNSData_AES256_Test class]];
	
	[tableView reloadData];
	return self;
}

#pragma mark -
#pragma mark dealloc

- (void)dealloc {
	DNSLogMethod
	[testClasses release];
    [super dealloc];
}

@end
