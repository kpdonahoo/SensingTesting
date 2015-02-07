//
//  ViewController.m
//  SensingTesting
//
//  Created by Kevin Donahoo on 2/6/15.
//  Copyright (c) 2015 Sharkbait. All rights reserved.
//

#import "ViewController.h"
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

@interface ViewController () <CvVideoCameraDelegate,NSURLSessionDelegate>
@property (strong, nonatomic) IBOutlet UIView *cameraOutput;
@property (nonatomic, strong) CvVideoCamera* videoCamera1;
@property (strong,nonatomic) NSURLSession *session;

@end

@implementation ViewController
NSString* dataString;
NSString* tempString;
float redArray1[360];
Mat imageFrames[360];
Mat filteredFrames[360];
vector<cv::Rect> objects;
int frameCount;
int testCheck = 1;
NSString *baseURL;
NSMutableDictionary *jsonUpload;
NSString *uuid = @"1234";
NSString *frame = @"37";
NSString *module = @"1";
NSString *page = @"3";
NSString *testImage = @"321";
NSString *result;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.videoCamera start];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 5.0;
    sessionConfig.timeoutIntervalForResource = 8.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    
    self.session = [NSURLSession sessionWithConfiguration: sessionConfig
                                                 delegate:self delegateQueue:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [self.videoCamera stop];
}

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

#ifdef __cplusplus
-(Byte *)matToBytes:(Mat&)image {
    int size = image.total() * image.elemSize();
    Byte * bytes = new Byte[size];  // you will have to delete[] that later
    memcpy(bytes,image.data,size * sizeof(Byte));
    NSData *dataData = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    //NSLog(@"data = %@", dataData);
    return bytes;
}


-(Mat&)bytesToMat:(Byte*)bytes :(int)width :(int)height {
    Mat image = Mat(height,width,CV_8UC3,bytes).clone(); // make a copy
    return image;
}

-(void)processImage:(Mat&)image; {
    Mat image_copy;
    Mat grayFrame, output;
    NSError *error = nil;
    
    Byte *temp_byte = [self matToBytes:image_copy];
//    NSLog(@"Converted to bytes.");
//    NSData *dataData = [NSData dataWithBytes:temp_byte length:sizeof(temp_byte)];
//    NSLog(@"data = %@", dataData);
    Mat image_copy_new = [self bytesToMat:temp_byte :640 :480];
    
    if(testCheck == 1) {
        NSLog(@"Bitch, I entered the thing");
        testCheck = 0;
        
        baseURL = [NSString stringWithFormat:@"%s/InsertImage", SERVER_URL];
        NSURL *postURL = [NSURL URLWithString:baseURL];
        
        jsonUpload = [[NSMutableDictionary alloc] init];
        [jsonUpload setObject:uuid forKey:@"uuid"];
        [jsonUpload setObject:module forKey:@"module"];
        [jsonUpload setObject:page forKey:@"page"];
        [jsonUpload setObject:frame forKey:@"frame"];
        [jsonUpload setObject:testImage forKey:@"image"];
        
        NSData *requestBody = [NSJSONSerialization dataWithJSONObject:jsonUpload options:NSJSONWritingPrettyPrinted error:&error];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:postURL];
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
    
//    NSLog(@"Converted back to mat.");
    
    cvtColor(image, image_copy_new, CV_BGRA2BGR); //get rid of alpha for processing
    
    imageFrames[frameCount] = image_copy;
    frameCount++;
    
    if(frameCount > 359) {
        //Analyze copy of the array
        frameCount = 0;
    }
    
}
#endif

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
