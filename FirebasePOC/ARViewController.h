//
//  ARViewController.h
//  FirebasePOC
//
//  Created by Ann Mac on 11/07/17.
//  Copyright © 2017 MACMINI 2. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ARKit.h"
#import "DetailView.h"

@interface ARViewController : UIViewController<ARViewDelegate,CLLocationManagerDelegate>  {
    ARKitEngine *engine;
    NSInteger selectedIndex;
    DetailView *currentDetailView;
    NSMutableArray * arrGeoPoints;
}

@property (nonatomic,strong) NSMutableArray *arrPoints;

@end
