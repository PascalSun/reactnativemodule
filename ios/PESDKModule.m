//
//  PESDKModule.m
//  TestNative
//
//  Created by PascalSun on 31/7/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "PESDKModule.h"
#import <React/RCTUtils.h>
#import <PhotoEditorSDK/PhotoEditorSDK.h>
#import <React/RCTLog.h>

@interface PESDKModule () <PESDKPhotoEditViewControllerDelegate>
@end

@implementation PESDKModule

RCT_EXPORT_MODULE(PESDK);

RCT_EXPORT_METHOD(present:(NSString *)path) {
  dispatch_async(dispatch_get_main_queue(), ^{
    PESDKPhotoEditViewController *photoEditViewController = [[PESDKPhotoEditViewController alloc] initWithPhotoAsset:[[PESDKPhoto alloc] initWithData:[NSData dataWithContentsOfFile:path]] configuration:[[PESDKConfiguration alloc] init]];
    photoEditViewController.delegate = self;
    
    UIViewController *currentViewController = RCTPresentedViewController();
    [currentViewController presentViewController:photoEditViewController animated:YES completion:NULL];
  });
}

- (PESDKConfiguration *)buildConfiguration {
  PESDKConfiguration *configuration = [[PESDKConfiguration alloc] initWithBuilder:^(PESDKConfigurationBuilder * _Nonnull builder) {
    // Configure camera
    [builder configureCameraViewController:^(PESDKCameraViewControllerOptionsBuilder * _Nonnull options) {
      // Just enable Photos
      options.allowedRecordingModesAsNSNumbers = @[@(RecordingModePhoto)];
    }];
  }];
  
  return configuration;
}

RCT_EXPORT_METHOD(camera:(NSString *)name){
  RCTLogInfo(@"STATUS");
  dispatch_async(dispatch_get_main_queue(), ^{
    PESDKConfiguration *configuration = [self buildConfiguration];
    PESDKCameraViewController *cameraViewController = [[PESDKCameraViewController alloc] initWithConfiguration:configuration];
    __weak PESDKCameraViewController *weakCameraViewController = cameraViewController;

    UIViewController *currentViewController = RCTPresentedViewController();
    [currentViewController presentViewController:cameraViewController animated:YES completion:NULL];
  });
}

#pragma mark - IMGLYPhotoEditViewControllerDelegate

- (void)photoEditViewController:(PESDKPhotoEditViewController *)photoEditViewController didSaveImage:(UIImage *)image imageAsData:(NSData *)data {
  [photoEditViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
    [self sendEventWithName:@"PhotoEditorDidSave" body:@{ @"image": [UIImageJPEGRepresentation(image, 1.0) base64EncodedStringWithOptions: 0], @"data": [data base64EncodedStringWithOptions:0] }];
  }];
}

- (void)photoEditViewControllerDidCancel:(PESDKPhotoEditViewController *)photoEditViewController {
  [photoEditViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
    [self sendEventWithName:@"PhotoEditorDidCancel" body:@{}];
  }];
}

- (void)photoEditViewControllerDidFailToGeneratePhoto:(PESDKPhotoEditViewController *)photoEditViewController {
  [self sendEventWithName:@"PhotoEditorDidFailToGeneratePhoto" body:@{}];
}

#pragma mark - RCTEventEmitter

- (NSArray<NSString *> *)supportedEvents {
  return @[ @"PhotoEditorDidSave", @"PhotoEditorDidCancel", @"PhotoEditorDidFailToGeneratePhoto" ];
}

@end
