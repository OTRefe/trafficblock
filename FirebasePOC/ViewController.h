//
//  ViewController.h
//  FirebasePOC
//
//  Created by Ann Mac on 03/07/17.
//  Copyright © 2017 MACMINI 2. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
@import Firebase;

@interface ViewController : UIViewController<MKMapViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) FIRDatabaseReference *FIRDbRef;

@property (nonatomic, strong) CLLocation* currentLocation;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) IBOutlet UIButton *homeButton;
@property (strong, nonatomic) IBOutlet UIButton *yourLocationButton;

- (IBAction)segmentedControlClicked:(id)sender;
- (IBAction)homeButtonClicked:(UIButton *)sender;
- (IBAction)yourLocationClicked:(UIButton *)sender;

-(void)locDetails:(NSString *)title :(void (^)(NSDictionary *dict, NSError *error)) completionBlock;

@end

