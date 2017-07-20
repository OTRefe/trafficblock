//
//  ViewController.h
//  FirebasePOC
//
//  Created by Ann Mac on 03/07/17.
//  Copyright © 2017 MACMINI 2. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AnimatedCircleView.h"
#import "ARViewController.h"
@import Firebase;

@interface TrafficViewController : UIViewController<MKMapViewDelegate,CLLocationManagerDelegate>

@property (strong, nonatomic) FIRDatabaseReference *FIRDbRef;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) IBOutlet UIButton *btnStreetView;
@property (strong, nonatomic) IBOutlet UIButton *btnRefresh;


- (IBAction)segmentedControlClicked:(id)sender;
- (IBAction)btnStreetViewClicked:(id)sender;
- (IBAction)btnRefreshClicked:(id)sender;

-(void)drawOverlay;
-(void)locDetails:(NSString *)title :(void (^)(NSDictionary *dict, NSError *error)) completionBlock;
-(void)addDataToFirebase:(NSString *)title;
-(void)showActivityIndicator;
-(void)hideActivityIndicator;
-(void)getOverlays;

@end

