//
//  CEMovieMaker.m
//  CEMovieMaker
//
//  Created by Cameron Ehrlich on 9/17/14.
//  Copyright (c) 2014 Cameron Ehrlich. All rights reserved.
//

#import "CEMovieMaker.h"

typedef UIImage*(^CEMovieMakerUIImageExtractor)(NSObject* inputObject);

@implementation CEMovieMaker


- (instancetype)initWithSettings:(NSDictionary *)videoSettings frameTime: (CMTime)frameTime  url: (NSURL *)url frameCount: (NSInteger)frameCount;
{
    self = [self init];
    if (self) {
        NSError *error;
        _fileURL = url;
        _assetWriter = [[AVAssetWriter alloc] initWithURL: self.fileURL
                                                 fileType: AVFileTypeQuickTimeMovie error:&error];
        if (error) {
            NSLog(@"Error: %@", error.debugDescription);
        }
        NSParameterAssert(self.assetWriter);
        
        _videoSettings = videoSettings;
        _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                          outputSettings:videoSettings];
        NSParameterAssert(self.writerInput);
        NSParameterAssert([self.assetWriter canAddInput:self.writerInput]);
        
        [self.assetWriter addInput:self.writerInput];
        
        NSDictionary *bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
        
        _bufferAdapter = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.writerInput sourcePixelBufferAttributes:bufferAttributes];
        self.frameTime = frameTime;
        self.frameCount = frameCount;
    }
    return self;
}

- (void) createMovieFromImageURLs:(NSArray CE_GENERIC_URL*)urls withCompletion:(CEMovieMakerCompletion)completion;
{
    [self createMovieFromSource:urls extractor:^UIImage *(NSObject *inputObject) {
        return [UIImage imageWithData: [NSData dataWithContentsOfURL:((NSURL*)inputObject)]];
    } withCompletion:completion];
}

- (void) createMovieFromImages:(NSArray CE_GENERIC_IMAGE *)images withCompletion:(CEMovieMakerCompletion)completion;
{
    [self createMovieFromSource:images extractor:^UIImage *(NSObject *inputObject) {
        return (UIImage*)inputObject;
    } withCompletion:completion];
}

- (void) createMovieFromSource:(NSArray *)images extractor:(CEMovieMakerUIImageExtractor)extractor withCompletion:(CEMovieMakerCompletion)completion;
{
    self.completionBlock = completion;
    
    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);

    [self.writerInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock:^{
        
        __block NSInteger i = 0;
        NSInteger frameNumber = self.frameCount;
        UIImage* img = extractor([images objectAtIndex: 0]);
        CVPixelBufferRef sampleBuffer = [self newPixelBufferFromCGImage:[img CGImage]];

        while (YES) {
            if (i >= frameNumber) {
                break;
            }
            if ([self.writerInput isReadyForMoreMediaData]) {
                if (sampleBuffer) {
                    if (i == 0) {
                        [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:kCMTimeZero];
                    } else {
                        CMTime lastTime = CMTimeMake(i-1, self.frameTime.timescale);
                        CMTime presentTime = CMTimeAdd(lastTime, self.frameTime);
                        [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:presentTime];
                    }
                    i++;
                }
            }
        }
        CFRelease(sampleBuffer);

        
        [self.writerInput markAsFinished];
        [self.assetWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionBlock(self.fileURL);
            });
        }];
        
        CVPixelBufferPoolRelease(self.bufferAdapter.pixelBufferPool);
    }];
}


- (CVPixelBufferRef)newPixelBufferFromCGImage:(CGImageRef)image
{
    CGFloat frameWidth = [[self.videoSettings objectForKey:AVVideoWidthKey] floatValue];
    CGFloat frameHeight = [[self.videoSettings objectForKey:AVVideoHeightKey] floatValue];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    
    NSInteger x = 0; // (( CGImageGetWidth(image)  - (NSInteger)(frameWidth) ) / 2);
    NSInteger y = 0; // (( CGImageGetHeight(image) - (NSInteger)(frameHeight)) / 2);
    NSInteger w = (NSInteger)(frameWidth);
    NSInteger h = (NSInteger)(frameHeight);
    
    CGContextDrawImage(context, CGRectMake(x, y, w, h),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+ (NSDictionary *)videoSettingsWithCodec:(NSString *)codec withWidth:(CGFloat)width andHeight:(CGFloat)height
{
    
    if ((int)width % 16 != 0 ) {
        NSLog(@"Warning: video settings width must be divisible by 16.");
    }
    
    NSDictionary *videoSettings = @{AVVideoCodecKey  : AVVideoCodecTypeH264,
                                    AVVideoWidthKey  : [NSNumber numberWithInt:(int)width],
                                    AVVideoHeightKey : [NSNumber numberWithInt:(int)height]};
    
    return videoSettings;
}

@end
