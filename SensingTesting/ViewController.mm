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
using namespace cv;

@interface ViewController () <CvVideoCameraDelegate>
@property (strong, nonatomic) IBOutlet UIView *cameraOutput;
@property (nonatomic, strong) CvVideoCamera* videoCamera1;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewWillDisappear:(BOOL)animated {
    [self.videoCamera stop];
}

-(CvVideoCamera *)videoCamera{
    if(!_videoCamera1) {
        _videoCamera1 = [[CvVideoCamera alloc] initWithParentView:self.cameraOutput];
        _videoCamera1.delegate = self;
        _videoCamera1.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
        _videoCamera1.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
        _videoCamera1.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        _videoCamera1.defaultFPS = 24;
        _videoCamera1.grayscaleMode = NO;
    }
    return _videoCamera1;
}

#ifdef __cplusplus
-(void)processImage:(Mat&)image; {
    Mat image_copy;
    Mat grayFrame, output;
    
    cvtColor(image, image_copy, CV_BGRA2BGR); //get rid of alpha for processing
    
}
#endif

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
