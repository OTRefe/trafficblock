//
//  AnimatedCircleView.m
//  FirebasePOC
//
//  Created by Ann Mac on 10/07/17.
//  Copyright © 2017 MACMINI 2. All rights reserved.
//

#import "AnimatedCircleView.h"

@implementation AnimatedCircleView

#define MAX_RATIO 1.2
#define MIN_RATIO 0.8
#define STEP_RATIO 0.05

#define ANIMATION_DURATION 1

//repeat forever
#define ANIMATION_REPEAT HUGE_VALF


-(id)initWithCircle:(MKCircle *)circle{
    
    self = [super initWithCircle:circle];
    
    if(self){
        [self start];
    }
    return self;
}

-(void)dealloc{
    [self removeExistingAnimation];
}

-(void)start{
    [self removeExistingAnimation];
    
    //create the image
     UIImage* img;
    _imageView = [[UIImageView alloc] initWithImage:img];
    _imageView.frame = CGRectMake(0, 0, 0, 0);
    [self addSubview:_imageView];
    
    //opacity animation setup
    CABasicAnimation *opacityAnimation;
    
    opacityAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.duration = ANIMATION_DURATION;
    opacityAnimation.repeatCount = ANIMATION_REPEAT;
    //theAnimation.autoreverses=YES;
    opacityAnimation.fromValue = [NSNumber numberWithFloat:0.2];
    opacityAnimation.toValue = [NSNumber numberWithFloat:0.025];
    
    //resize animation setup
    CABasicAnimation *transformAnimation;
    
    transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    
    transformAnimation.duration = ANIMATION_DURATION;
    transformAnimation.repeatCount = ANIMATION_REPEAT;
    //transformAnimation.autoreverses=YES;
    transformAnimation.fromValue = [NSNumber numberWithFloat:MIN_RATIO];
    transformAnimation.toValue = [NSNumber numberWithFloat:MAX_RATIO];
    
    
    //group the two animation
    CAAnimationGroup *group = [CAAnimationGroup animation];
    
    group.repeatCount = ANIMATION_REPEAT;
    [group setAnimations:[NSArray arrayWithObjects:opacityAnimation, transformAnimation, nil]];
    group.duration = ANIMATION_DURATION;
    
    //apply the grouped animaton
    [_imageView.layer addAnimation:group forKey:@"groupAnimation"];
}


-(void)stop{
    [self removeExistingAnimation];
}

-(void)removeExistingAnimation{
    if(_imageView){
        [_imageView.layer removeAllAnimations];
        [_imageView removeFromSuperview];
        _imageView = nil;
    }
}


- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)ctx {
    
    //the circle center
    MKMapPoint mpoint = MKMapPointForCoordinate([[self overlay] coordinate]);
    
    //geting the radius in map point
    double radius = [(MKCircle*)[self overlay] radius];
    double mapRadius = radius * MKMapPointsPerMeterAtLatitude([[self overlay] coordinate].latitude);
    
    //calculate the rect in map coordination
    MKMapRect mrect = MKMapRectMake(mpoint.x - mapRadius, mpoint.y - mapRadius, mapRadius * 2, mapRadius * 2);
    
    //get the rect in pixel coordination and set to the imageView
    CGRect rect = [self rectForMapRect:mrect];
    dispatch_async(dispatch_get_main_queue(), ^{
        if(_imageView){
            _imageView.frame = rect;
        }
    });
}

@end
