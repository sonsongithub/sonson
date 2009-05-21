//
//  UICNSData+AES256_Test.m
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
//  Created by sonson on 09/05/12.
//  Copyright 2009 sonson, sonson@Picture&Software. All rights reserved.
//

#import "UICNSData+AES256_Test.h"
#import "UICNSData+AES256.h"

@implementation UICNSData_AES256_Test

// NSData AES Encryption test
+ (void)test:(id)object {
	NSLog(@"UICNSData_AES256_Test");
	
	int test_count = 0;
	int ok_count = 0;
	
	NSString *originalKey = @"0123456789abcdefghijklmnopqrstuv";
	char *p = "The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.";
	int test_data_length = strlen(p);
	
	for (int j = 1; j <= [originalKey length]; j++) {
		// check, key length
		NSString *key = [originalKey substringWithRange:NSMakeRange(0, j)];
		for (int i = test_data_length/2; i < test_data_length; i++) {
			// check, byte length
			NSData *data = [NSData dataWithBytes:p length:i];
			NSData *encrypted = [data dataEncryptedWithKey:key];
			NSData *decrypted = [encrypted dataDecryptedWithKey:key];
			
			BOOL encryptResult = (encrypted != nil);
			BOOL decryptedResult = (decrypted != nil);
			BOOL decryptedConfirmResult = [data isEqualToData:decrypted];
			
			test_count++;
			
			if (!encryptResult) {
				NSLog(@"Pattern %dbytes, key length %d Encrypt Failed", i, j);
				continue;
			}
			if (!decryptedResult) {
				NSLog(@"Pattern %dbytes, key length %d Decrypt Failed", i, j);
				continue;
			}
			if (!decryptedConfirmResult) {
				NSLog(@"Pattern %dbytes, key length %d Restore Failed", i, j);
				continue;
			}
			ok_count++;
		}
	}
	NSLog(@"Test result OK = %d/%d", ok_count, test_count);
}

@end
