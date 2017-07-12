//
//  ARViewController.m
//  FirebasePOC
//
//  Created by Ann Mac on 11/07/17.
//  Copyright © 2017 MACMINI 2. All rights reserved.
//

#import "ARViewController.h"

@implementation ARViewController

@synthesize arrPoints;

-(void)viewDidLoad{
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    [locationManager requestWhenInUseAuthorization];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    
    selectedIndex = -1;
    
    arrGeoPoints=[[NSMutableArray alloc]init];
    
    for(NSDictionary *dict in arrPoints){
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[[dict valueForKey:@"latitude"] floatValue] longitude:[[dict valueForKey:@"longitude"] floatValue]];
        ARGeoCoordinate *geoCoordinate = [ARGeoCoordinate coordinateWithLocation:location];
        geoCoordinate.dataObject =dict; // [NSString stringWithFormat:@"%@",[dict valueForKey:@"type"]];
        [arrGeoPoints addObject:geoCoordinate];
    }
    
    [self showAR];
}

#pragma mark - ARViewDelegate protocol Methods

-(ARObjectView *)viewForCoordinate:(ARGeoCoordinate *)coordinate floorLooking:(BOOL)floorLooking{
    //NSString *text = (NSString *)coordinate.dataObject;
    //NSLog(@"text: %@",text);
    
    NSDictionary *dict = (NSDictionary *)coordinate.dataObject;
    NSString *text =[dict valueForKey:@"type"];
    
    float distanceInKM=([[dict valueForKey:@"distance"]floatValue]/1000);
    
    NSString *distance =[NSString stringWithFormat:@"%.02f KM", distanceInKM];
    
    ARObjectView *view = nil;
    
    if(floorLooking){
        UIImage *arrowImg = [UIImage imageNamed:@"arrow"];
        UIImageView *arrowView = [[UIImageView alloc] initWithImage:arrowImg];
        view = [[ARObjectView alloc] initWithFrame:arrowView.bounds];
        [view addSubview:arrowView];
        view.displayed = NO;
    }else{
        
        NSString *imageName=@"";
        
        if ([text isEqualToString:@"Block"]) {
            imageName = @"red box";
        }else if ([text isEqualToString:@"Slow Moving"]){
            imageName = @"blue box";
        }else{
            imageName = @"green box"; //"Free Moving"
        }
        
        UIImageView *boxView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
        boxView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(4, 25, boxView.frame.size.width - 8, 20)];
        lbl.font = [UIFont boldSystemFontOfSize:10];
        lbl.minimumFontSize = 2;
        lbl.backgroundColor = [UIColor clearColor];
        lbl.textColor = [UIColor whiteColor];
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.text = distance;
        lbl.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        
        view = [[ARObjectView alloc] initWithFrame:boxView.frame];
        [view addSubview:boxView];
        [view addSubview:lbl];
    }
    
    [view sizeToFit];
    return view;
}

-(void)itemTouchedWithIndex:(NSInteger)index{
    selectedIndex = index;
    NSDictionary *dict =[engine dataObjectWithIndex:index];
    
    float distanceInKM=([[dict valueForKey:@"distance"]floatValue]/1000);
    NSString *distance =[NSString stringWithFormat:@"%.02f KM", distanceInKM];
    
    NSString *name = [NSString stringWithFormat:@"Distance: %@\nType: %@\nRoad: %@",distance,[dict valueForKey:@"type"],[dict valueForKey:@"placemark"]];
    currentDetailView = [[NSBundle mainBundle] loadNibNamed:@"DetailView" owner:nil options:nil][0];
    currentDetailView.nameLbl.text = name;
    [engine addExtraView:currentDetailView];
}

-(void)didChangeLooking:(BOOL)floorLooking{
    if(floorLooking){
        if(selectedIndex != -1){
            [currentDetailView removeFromSuperview];
            ARObjectView *floorView = [engine floorViewWithIndex:selectedIndex];
            floorView.displayed = YES;
        }
    } else{
        if(selectedIndex != -1){
            ARObjectView *floorView = [engine floorViewWithIndex:selectedIndex];
            floorView.displayed = NO;
            selectedIndex = -1;
        }
    }
}

#pragma mark - Custom Methods

-(void)showAR{
    
    ARKitConfig *config = [ARKitConfig defaultConfigFor:self];
    config.orientation = self.interfaceOrientation;
    
    CGSize s = [UIScreen mainScreen].bounds.size;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        config.radarPoint = CGPointMake(s.width - 50, s.height - 50);
    }else {
        config.radarPoint = CGPointMake(s.height - 50, s.width - 50);
    }
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [closeBtn sizeToFit];
    [closeBtn addTarget:self action:@selector(closeAr) forControlEvents:UIControlEventTouchUpInside];
    closeBtn.center = CGPointMake(50, 50);
    
    engine = [[ARKitEngine alloc] initWithConfig:config];
    [engine addCoordinates:arrGeoPoints];
    [engine addExtraView:closeBtn];
    [engine startListening];
}

-(void) closeAr {
    [engine hide];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)btnCloseClicked:(id)sender {
    [self closeAr];
}
@end
