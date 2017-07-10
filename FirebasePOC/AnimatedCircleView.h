//
//  AnimatedCircleView.h
//  FirebasePOC
//
//  Created by Ann Mac on 10/07/17.
//  Copyright © 2017 MACMINI 2. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>

@interface AnimatedCircleView : MKCircleView{
  //  UIImageView* imageView;
}

-(void)start;
-(void)stop;
-(void)removeExistingAnimation;

@property(strong, nonatomic)UIImageView *imageView;
@end
