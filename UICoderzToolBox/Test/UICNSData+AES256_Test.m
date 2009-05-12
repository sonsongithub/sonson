//
//  UICNSData+AES256_Test.m
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

+ (void)test {
	// NSData AES Encryption test
	char *p = "0123456789012345678901234567890123456789";
	NSString *key = @"123456";
	NSData *data = [NSData dataWithBytes:p length:strlen(p)];
	NSLog(@"data - original - %@", data);
	
	NSData *encrypted = [data dataEncryptedWithKey:key];	
	if (encrypted) {
		NSLog(@"encrypted - OK - %@", encrypted);
		NSData *decrypted = [encrypted dataDecryptedWithKey:key];
		if (decrypted) {
			NSLog(@"decrypted - OK - %@", decrypted);
		}
		NSLog(@"Encrypt -> Decrypt Test");
		if ([decrypted length] == [data length]) {
			int sum = 0;
			const char* originalBytes = [data bytes];
			const char* decryptedBytes = [decrypted bytes];
			for(int i = 0; i < [decrypted length]; i++) {
				if (originalBytes[i] != decryptedBytes[i]) {
					sum++;
				}
			}
			if (sum > 0) {
				NSLog(@"Encrypt -> Decrypt Test:Byte check error");
			}
		}
		else {
			NSLog(@"Encrypt -> Decrypt Test:size wrong");
		}
	}
}

@end
