//
//  DRPLoadingSpinner.m
//  DRPLoadingSpinner
//
//  Created by Justin Hill on 11/11/14.
//  Copyright (c) 2014 Justin Hill. All rights reserved.
//

#import "DRPLoadingSpinner.h"

#define kInvalidatedTimestamp -1

@interface DRPLoadingSpinner () {
    BOOL _animating;
}

@property (strong) CADisplayLink *displayLink;
@property CFTimeInterval animationStartTime;
@property CGFloat lastFrameDrawPercentage;
@property BOOL erasing;
@property NSUInteger colorIndex;

@end

@implementation DRPLoadingSpinner

#pragma mark - Life cycle
- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    self.clearsContextBeforeDrawing = YES;
    self.animationStartTime = kInvalidatedTimestamp;
    self.drawCycleDuration = .75;
    self.rotationCycleDuration = 4;
    
    self.colorSequence = @[
        [UIColor redColor],
        [UIColor orangeColor],
        [UIColor purpleColor],
        [UIColor blueColor]
    ];
    
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
}

#pragma mark - Property accessors
- (BOOL)isAnimating {
    return _animating;
}

#pragma mark - Animation control
- (void)startAnimating {
    if (self.displayLink) {
        [self stopAnimating];
    }
    
    self.colorIndex = 0;
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(setNeedsDisplay)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    _animating = YES;
}

- (void)stopAnimating {
    self.animationStartTime = kInvalidatedTimestamp;
    [self.displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    self.displayLink = nil;
    _animating = NO;
    
    [self setNeedsDisplay];
}

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect {
    
    if (!self.isAnimating) {
        return;
    }
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    if (self.animationStartTime == kInvalidatedTimestamp) {
        self.animationStartTime = self.displayLink.timestamp;
    }
    
    CFTimeInterval elapsedDrawCycleTime = fmodf(self.displayLink.timestamp - self.animationStartTime, self.drawCycleDuration);
    
    CGFloat drawPercentComplete = [self sinEaseInOutWithCurrentTime:elapsedDrawCycleTime
                                                           startVal:0
                                                             change:1
                                                           duration:self.drawCycleDuration];
    
    if (drawPercentComplete < self.lastFrameDrawPercentage) {
        self.erasing = !self.erasing;
        
        if (!self.erasing) {
            self.colorIndex = (self.colorIndex + 1) % self.colorSequence.count;
        }
    }
    self.lastFrameDrawPercentage = drawPercentComplete;
    
    CGFloat rotationPercentComplete = fmodf(self.displayLink.timestamp - self.animationStartTime, self.rotationCycleDuration) / self.rotationCycleDuration;
    CGFloat rotationAngle = rotationPercentComplete * 2 * M_PI;
    
    CGFloat x = rect.size.width / 2;
    CGFloat y = rect.size.height / 2;
    
    CGFloat startAngle;
    CGFloat endAngle;
    
    if (self.erasing) {
        endAngle = -M_PI_2 + rotationAngle;
        startAngle = (drawPercentComplete * 2 * M_PI) - M_PI_2 + rotationAngle;
    } else {
        startAngle = -M_PI_2 + rotationAngle;
        endAngle = (drawPercentComplete * 2 * M_PI) - M_PI_2 + rotationAngle;
    }
    
    CGContextAddArc(ctx, x, y, 12, startAngle, endAngle, 0);
    
    CGContextSetStrokeColorWithColor(ctx, [self.colorSequence[self.colorIndex] CGColor]);
    CGContextSetLineWidth(ctx, 1);
    CGContextStrokePath(ctx);
}

#pragma mark - Auto Layout
- (CGSize)intrinsicContentSize {
    return CGSizeMake(40, 40);
}

#pragma mark - Easing
- (double)sinEaseInOutWithCurrentTime:(double)t startVal:(double)b change:(double)c duration:(double)d {
    return -c/2 * (cos(M_PI * t / d) - 1) + b;
}

@end
