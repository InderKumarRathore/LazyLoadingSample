/*
 File: IconDownloader.m
 Abstract: Helper object for managing the downloading of a particular app's icon.
 As a delegate "NSURLConnectionDelegate" is downloads the app icon in the background if it does not
 yet exist and works in conjunction with the RootViewController to manage which apps need their icon.
 
 Version: 1.4
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "IconDownloader.h"
#import "MLog.h"

@interface IconDownloader ()
@property (nonatomic, strong) NSMutableData *activeDownload;
@property (nonatomic, strong) NSURLConnection *imageConnection;
@end


@implementation IconDownloader

#pragma mark - class methods

- (void)startDownload {
  NSAssert(nil != self.iconDirName, @"iconDirName must be non-nil");
  //check image is present in doc dir
  NSString *imagePath = [self imagePath];

  if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
    MLog(@"%@ is present in doc dir, we're not downloading it", self.iconName);
    // call our delegate and tell it that our icon is ready for display
    if (self.completionHandler)
      self.completionHandler();
    return;
  }

  self.activeDownload = [NSMutableData data];

  //send request to image url
  MLog(@"Image downloading from : %@", self.iconUrl);
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[self.iconUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];

  // alloc+init and start an NSURLConnection; release on completion/failure
  NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];

  self.imageConnection = conn;
}

- (void)cancelDownload {
  [self.imageConnection cancel];
  self.completionHandler = nil;
  self.imageConnection = nil;
  self.activeDownload = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  if ([response respondsToSelector:@selector(statusCode)])
  {
    int statusCode = (int)[((NSHTTPURLResponse *)response) statusCode];
    if (statusCode == 404)
    {
      [connection cancel];  // stop connecting; no more delegate messages
      MLog(@"didReceiveResponse statusCode with %i", statusCode);
      // Clear the activeDownload property to allow later attempts
      self.activeDownload = nil;

      // Release the connection now that it's finished
      self.imageConnection = nil;
    }
  }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  [self.activeDownload appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  MLog(@"image downloading failed %@", error.description);
  // Clear the activeDownload property to allow later attempts
  self.activeDownload = nil;

  // Release the connection now that it's finished
  self.imageConnection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  NSString *imagePath = [self imagePath];

  NSError *error = nil;
  [[NSFileManager defaultManager] createDirectoryAtPath:[imagePath stringByDeletingLastPathComponent]
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:&error];

  if(!error) {
    [self.activeDownload writeToFile:imagePath atomically:NO];
    MLog(@"File name-%@",imagePath);
  }

  self.activeDownload = nil;

  // Release the connection now that it's finished
  self.imageConnection = nil;

  // call our delegate and tell it that our icon is ready for display
  if (self.completionHandler)
    self.completionHandler();
}
/**
 @return the image path
 */
- (NSString *)imagePath {
  return [NSString stringWithFormat:@"%@%@/%@", NSTemporaryDirectory(), self.iconDirName, self.iconName];
}

/**
 @return the image path
 */
+ (NSString *)imagePath:(NSString *)dirName iconName:(NSString *)iconName {
  return [NSString stringWithFormat:@"%@%@/%@", NSTemporaryDirectory(), dirName, iconName];
}
@end

