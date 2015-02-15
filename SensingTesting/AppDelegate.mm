//
//  AppDelegate.m
//  SensingTesting
//
//  Created by Kevin Donahoo on 2/6/15.
//  Copyright (c) 2015 Sharkbait. All rights reserved.
//

#import "AppDelegate.h"
#ifdef __cplusplus
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/highgui/highgui_c.h>
#import <opencv2/core/core.hpp>
#endif
#define SERVER_URL "http://ec2-54-69-199-135.us-west-2.compute.amazonaws.com:8000"
using namespace cv;
using namespace std;

@interface AppDelegate () <CvVideoCameraDelegate,NSURLSessionDelegate>

@property (strong, nonatomic) IBOutlet UIView *cameraOutput;
@property (nonatomic, strong) CvVideoCamera* videoCamera1;
@property (strong,nonatomic) NSURLSession *session;

@end

@implementation AppDelegate

-(CvVideoCamera *)videoCamera{
    if(!_videoCamera1) {
        _videoCamera1 = [[CvVideoCamera alloc] initWithParentView:self.cameraOutput];
        _videoCamera1.delegate = self;
        _videoCamera1.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
        _videoCamera1.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
        _videoCamera1.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        _videoCamera1.defaultFPS = 24;
        _videoCamera1.grayscaleMode = NO;
    }
    return _videoCamera1;
}

#ifdef _cplusplus
-(void)processImage:(Mat&)image; {
    NSLog(@"hey");
    Mat grayFrame, output;
    NSError *error = nil;
    
    imageFrames[frameCount] = image;
    frameCount++;
    
    if(frameCount > 24) {
        frameCount = 0;
        
        jsonUpload = [[NSMutableDictionary alloc] init];
        [jsonUpload setObject:uuid forKey:@"uuid"];
        [jsonUpload setObject:module forKey:@"module"];
        [jsonUpload setObject:page forKey:@"page"];
        frame = [NSString stringWithFormat:@"%d", frameNumber];
        frameNumber = frameNumber + 1;
        [jsonUpload setObject:frame forKey:@"frame"];
        
        baseURL = [NSString stringWithFormat:@"%s/InsertImage", SERVER_URL];
        NSURL *postURL = [NSURL URLWithString:baseURL];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:postURL];
        
        for(int i = 0; i < 24; i++) {
            UIImage *uImage = [self imageWithCVMat:imageFrames[i]];
            NSData *dataObj = UIImageJPEGRepresentation(uImage, 1.0);
            int bytes = [dataObj length];
            //NSLog(@"%@", dataObj);
            
            NSString *byteArray = [dataObj base64Encoding];
            
            //NSLog(byteArray);
            
            /*Mat byteImage = image;
             vector<Byte> v_char;
             for(int i = 0; i < byteImage.rows; i++) {
             for(int j = 0; j < image.cols; j++) {
             v_char.push_back(*(uchar*)(image.data + i*image.step + j));
             }
             }*/
            NSString *thisTemp = [NSString stringWithFormat:@"image%d", i];
            NSLog(thisTemp);
            [jsonUpload setObject:byteArray forKey:thisTemp];
            
        }
        
        NSData *requestBody = [NSJSONSerialization dataWithJSONObject:jsonUpload options:NSJSONWritingPrettyPrinted error:&error];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:requestBody];
        NSURLSessionDataTask *postTask = [self.session dataTaskWithRequest:request
                                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                             NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData: data
                                                                                                                  options:
                                                                                   NSJSONReadingMutableContainers error: &error];
                                                             NSLog(@"meow:%@", [JSON valueForKey:@"result"]);
                                                             result = [JSON valueForKey:@"result"];
                                                             NSLog(@"%@",result);
                                                             
                                                         }];
        [postTask resume];
        
    }
    
}
#endif

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [self.videoCamera start];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
