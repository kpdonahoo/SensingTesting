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
Mat image_new;
vector<cv::Rect> objects;
int frameCount;
int testCheck = 1;
int frameNumber = 1;
NSString *baseURL;
NSMutableDictionary *jsonUpload;
NSString *uuid = @"1234";
NSString *frame;
NSString *module = @"1";
NSString *page = @"3";
NSString *testImage = @"321";
NSString *result;
NSData *imageData;
NSString *tempImage;

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

-(NSString*)NSStringFromCvMat:(Mat)mat{
    stringstream ss;
    ss << mat;
    return [NSString stringWithCString:ss.str().c_str() encoding:NSASCIIStringEncoding];
}

-(UIImage *)imageWithCVMat:(const Mat&)cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    
    CGColorSpaceRef colorSpace;
    
    if(cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
        
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols,
                                        cvMat.rows,
                                        8,
                                        8 * cvMat.elemSize(),
                                        cvMat.step[0],
                                        colorSpace,
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault);
    
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

-(void)processImage:(Mat&)image; {
    Mat grayFrame, output;
    NSError *error = nil;
    
    if(testCheck < 24) {
        testCheck = testCheck + 1;
        
        UIImage *uImage = [self imageWithCVMat:image];
        NSData *dataObj = UIImageJPEGRepresentation(uImage, 1.0);
        int bytes = [dataObj length];
        //NSLog(@"%@", dataObj);
        
        NSString *byteArray = [dataObj base64Encoding];
        
        //NSLog(byteArray);
        
        baseURL = [NSString stringWithFormat:@"%s/InsertImage", SERVER_URL];
        NSURL *postURL = [NSURL URLWithString:baseURL];
        
        jsonUpload = [[NSMutableDictionary alloc] init];
        [jsonUpload setObject:uuid forKey:@"uuid"];
        [jsonUpload setObject:module forKey:@"module"];
        [jsonUpload setObject:page forKey:@"page"];
        frame = [NSString stringWithFormat:@"%d", frameNumber];
        frameNumber = frameNumber + 1;
        [jsonUpload setObject:frame forKey:@"frame"];
        
        Mat byteImage = image;
        vector<Byte> v_char;
        for(int i = 0; i < byteImage.rows; i++) {
            for(int j = 0; j < image.cols; j++) {
                v_char.push_back(*(uchar*)(image.data + i*image.step + j));
            }
        }
        
        [jsonUpload setObject:byteArray forKey:@"image"];
        
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
        
    } else {
        testCheck = testCheck + 1;

    }
    
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
