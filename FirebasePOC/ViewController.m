//
//  ViewController.m
//  FirebasePOC
//
//  Created by Ann Mac on 03/07/17.
//  Copyright © 2017 MACMINI 2. All rights reserved.
//

#import "ViewController.h"

@interface ViewController (){
    CLLocationManager *locManager;
    CLLocationCoordinate2D coordinate;
    CLLocation *userLoc;
    CLLocation *newLocation;
    NSString* strIdentifier;
    NSString *strAnnotationTitle;
    NSString *strSegmentTitle;
    NSDictionary *dictUserLoc;
    NSDictionary *dictLocDetails;
    NSMutableArray *arrOverlayDetails;
    NSNumber *latitude;
    NSNumber *longitude;
    NSInteger arrCount;
    NSMutableArray *arrLocations;
    MKCircleRenderer *circleRenderer;
    CLGeocoder *geoCoder;
    BOOL isKeyNull;
    __block NSDictionary *dictReturn;
    __block CLPlacemark *placemarkStartLoc;
    __block  CLPlacemark *placemarkEndLoc;
}

@end

@implementation ViewController

#pragma mark - View Cycles

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    locManager = [[CLLocationManager alloc]init];
    locManager.delegate = self;
    [locManager requestWhenInUseAuthorization];
    
    geoCoder = [[CLGeocoder alloc]init];
    arrLocations = [[NSMutableArray alloc]init];
    arrOverlayDetails = [[NSMutableArray alloc]init];
    [locManager startUpdatingLocation];
    
    //Customizing segmented control
    NSArray *arrSegments = [_segmentedControl subviews];
    // Change the tintColor of each subview within the array:
    [[arrSegments objectAtIndex:3] setBackgroundColor:[UIColor orangeColor]];
    [[arrSegments objectAtIndex:2] setBackgroundColor:[UIColor redColor]];
    [[arrSegments objectAtIndex:1] setBackgroundColor:[UIColor colorWithRed:0 green:255 blue:0 alpha:1]];
    [[arrSegments objectAtIndex:0] setBackgroundColor:[UIColor blueColor]];

    //Setting mapview type
    _mapView.mapType = MKMapTypeStandard;
    //Retrieve device unique ID
    strIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];

    self.FIRDbRef = [[FIRDatabase database] reference];
    _mapView.showsTraffic = YES;
    
    [_homeButton setHidden:YES];
    [_yourLocationButton setHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma  mark - Mapview delegate methods
/*
-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    latitude = [NSNumber numberWithDouble:userLocation.coordinate.latitude];//userlocation latitude
    longitude = [NSNumber numberWithDouble:userLocation.coordinate.longitude];//userlocation longtitude
    for (id annotation in _mapView.annotations){
        [_mapView removeAnnotation:annotation];
    }
    MKCoordinateRegion mapRegion;
    mapRegion.center = userLocation.coordinate;//setting mapview centre as userlocation coordinates
    mapRegion.span.latitudeDelta = 0.01;
    mapRegion.span.longitudeDelta = 0.01;
    [_mapView setRegion:mapRegion animated: YES];//setting mapview region as userlocation region
    
    userLoc = [[CLLocation alloc]initWithLatitude:userLocation.coordinate.latitude longitude:userLocation.coordinate.longitude];
    [geoCoder reverseGeocodeLocation:userLoc
              completionHandler:^(NSArray *placemarks, NSError *error) {
                 CLPlacemark *placemark = [placemarks objectAtIndex:0];
                  if(placemark) {
                      if(placemark.thoroughfare){
                          //NSLog(@" PLACEMARK :  %@",placemark.thoroughfare);
                          [arrLocations addObject:placemark.thoroughfare];
                          //NSLog(@"Location Array %@",arrLocations);
                      }
                  }
              }
     ];
}
*/


-(nullable MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    //Adding custom pin for annotation
    static NSString *cellIdent = @"Cell";
    MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:cellIdent];
    if(view == nil){
        view = [[MKAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:cellIdent];
    }

    view.image = [UIImage imageNamed:@"blue pin"];
    view.annotation = annotation;
    return view;
}
/*
-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    circleRenderer = [[MKCircleRenderer alloc]initWithOverlay:overlay];
    circleRenderer.strokeColor = [UIColor blackColor];
    circleRenderer.lineWidth = 1;
    for (NSDictionary *dict in arrOverlayDetails) {
        NSString *lat = [dict valueForKey:@"latitude"];
        NSString *lon = [dict valueForKey:@"longitude"];
        NSString *type = [dict valueForKey:@"type"];
        NSString *tmplat = [[NSString alloc] initWithFormat:@"%f", [overlay coordinate].latitude];
        NSString *tmplon = [[NSString alloc] initWithFormat:@"%f", [overlay coordinate].longitude];
        if(lat == tmplat && lon == tmplon){
            if ([type isEqualToString:@"Slow Moving"]){
                circleRenderer.fillColor = [UIColor colorWithDisplayP3Red:240/255 green:248/255 blue:255/255 alpha:0.4];
            }else if ([type isEqualToString:@"Block"]){
                circleRenderer.fillColor = [UIColor colorWithDisplayP3Red:255/255 green:0/255 blue:0/255 alpha:0.4];
            }else if ([type isEqualToString:@"Free Moving"]){
                circleRenderer.fillColor = [UIColor colorWithDisplayP3Red:224/255 green:255/255 blue:255/255 alpha:0.4];
            }
        }
    }
    return  circleRenderer;
}
*/
-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    AnimatedCircleView* circleView = [[AnimatedCircleView alloc] initWithCircle:(MKCircle *)overlay];
    
    circleRenderer = [[MKCircleRenderer alloc]initWithOverlay:overlay];
    circleRenderer.strokeColor = [UIColor blackColor];
    circleRenderer.lineWidth = 1;
    for (NSDictionary *dict in arrOverlayDetails) {
        NSString *lat = [dict valueForKey:@"latitude"];
        NSString *lon = [dict valueForKey:@"longitude"];
        NSString *type = [dict valueForKey:@"type"];
        NSString *tmplat = [[NSString alloc] initWithFormat:@"%f", [overlay coordinate].latitude];
        NSString *tmplon = [[NSString alloc] initWithFormat:@"%f", [overlay coordinate].longitude];
        if(lat == tmplat && lon == tmplon){
            if ([type isEqualToString:@"Slow Moving"]){
                circleView.imageView.image = [UIImage imageNamed:@"orange circle"];
               // circleView.fillColor = [UIColor colorWithDisplayP3Red:240/255 green:248/255 blue:255/255 alpha:0.4];
            }else if ([type isEqualToString:@"Block"]){
                circleView.imageView.image = [UIImage imageNamed:@"red circle"];
               // circleView.fillColor = [UIColor colorWithDisplayP3Red:255/255 green:0/255 blue:0/255 alpha:0.4];
            }else if ([type isEqualToString:@"Free Moving"]){
                circleView.imageView.image = [UIImage imageNamed:@"green circle"];
               // circleView.fillColor = [UIColor colorWithDisplayP3Red:224/255 green:255/255 blue:255/255 alpha:0.4];
            }
        }
    }

    return circleView ;
}

#pragma  mark - Mapview delegate methods

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLoc fromLocation:(CLLocation *)oldLocation{

    [_mapView removeOverlays:_mapView.overlays];
    [self addCircle:newLoc];
    latitude = [NSNumber numberWithDouble:newLoc.coordinate.latitude];//userlocation latitude
    longitude = [NSNumber numberWithDouble:newLoc.coordinate.longitude];//userlocation longtitude
    for (id annotation in _mapView.annotations){
        [_mapView removeAnnotation:annotation];
    }
    MKCoordinateRegion mapRegion;
    mapRegion.center = newLoc.coordinate;//setting mapview centre as userlocation coordinates
    mapRegion.span.latitudeDelta = 0.01;
    mapRegion.span.longitudeDelta = 0.01;
 //   [_mapView setRegion:mapRegion animated: YES];//setting mapview region as userlocation region
     [_mapView setRegion:MKCoordinateRegionMake(newLoc.coordinate, MKCoordinateSpanMake(0.01, 0.01)) animated:NO];
    userLoc = [[CLLocation alloc]initWithLatitude:newLoc.coordinate.latitude longitude:newLoc.coordinate.longitude];
    [geoCoder reverseGeocodeLocation:userLoc
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       CLPlacemark *placemark = [placemarks objectAtIndex:0];
                       if(placemark) {
                           if(placemark.thoroughfare){
                               NSLog(@" PLACEMARK :  %@",placemark.thoroughfare);
                               [arrLocations addObject:placemark.thoroughfare];
                               NSLog(@"Location Array %@",arrLocations);
                           }
                       }
                   }
     ];
}

#pragma mark - IB Action

- (IBAction)segmentedControlClicked:(id)sender {
    NSInteger intSelectedSegment = _segmentedControl.selectedSegmentIndex;
    strSegmentTitle = [_segmentedControl titleForSegmentAtIndex:_segmentedControl.selectedSegmentIndex];
    
    if(intSelectedSegment == 0){
        // SLOW MOVING CLICKED
        [self locDetails:strSegmentTitle :^(NSDictionary *dict,NSError *error) {
            dictLocDetails = dict;
            NSArray *keys = [dictLocDetails allKeys];
            NSLog(@"Keys : %@", keys);
            isKeyNull = false;
            [dictLocDetails enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
                if([object isEqual:NULL]){
                    stop = false;
                    isKeyNull = true;
                }
            }];
            if(!isKeyNull){
                [[[_FIRDbRef child:@"users"] child:[dictLocDetails valueForKey:@"UDID"]] setValue:@{@"type": [dictLocDetails valueForKey:@"Type"],@"startLocation":[dictLocDetails valueForKey:@"StartLocation"],@"endLocation":[dictLocDetails valueForKey:@"EndLocation"], @"latitude": [dictLocDetails valueForKey:@"Latitude"], @"longitude":[dictLocDetails valueForKey:@"Longitude"]}];
            }
        }];
    }else if (intSelectedSegment == 1){
        // BLOCK CLICKED
        [self locDetails:strSegmentTitle :^(NSDictionary *dict,NSError *error) {
            dictLocDetails = dict;
            NSArray *keys = [dictLocDetails allKeys];
            NSLog(@"Keys : %@", keys);
            isKeyNull = false;
            [dictLocDetails enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
                if([object isEqual:NULL]){
                    stop = false;
                    isKeyNull = true;
                }
            }];
            if(!isKeyNull){
                [[[_FIRDbRef child:@"users"] child:[dictLocDetails valueForKey:@"UDID"]] setValue:@{@"type": [dictLocDetails valueForKey:@"Type"],@"startLocation":[dictLocDetails valueForKey:@"StartLocation"],@"endLocation":[dictLocDetails valueForKey:@"EndLocation"], @"latitude": [dictLocDetails valueForKey:@"Latitude"], @"longitude":[dictLocDetails valueForKey:@"Longitude"]}];            }
        }];
    }else if (intSelectedSegment == 2){
        // FREE MOVING CLICKED
        [self locDetails:strSegmentTitle :^(NSDictionary *dict,NSError *error) {
            dictLocDetails = dict;
            NSArray *keys = [dictLocDetails allKeys];
            NSLog(@"Keys : %@", keys);
            isKeyNull = false;
            [dictLocDetails enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
                if([object isEqual:NULL]){
                    stop = false;
                    isKeyNull = true;
                }
            }];
            if(!isKeyNull){
                [[[_FIRDbRef child:@"users"] child:[dictLocDetails valueForKey:@"UDID"]] setValue:@{@"type": [dictLocDetails valueForKey:@"Type"],@"startLocation":[dictLocDetails valueForKey:@"StartLocation"],@"endLocation":[dictLocDetails valueForKey:@"EndLocation"], @"latitude": [dictLocDetails valueForKey:@"Latitude"], @"longitude":[dictLocDetails valueForKey:@"Longitude"]}];            }
        }];
    }else if (intSelectedSegment == 3){
        // TRAFFIC STATUS CLICKED
        [_segmentedControl setHidden:YES];
        [_homeButton setHidden:NO];
        [_yourLocationButton setHidden:NO];
        [locManager stopUpdatingLocation];
        dispatch_async(dispatch_get_main_queue(), ^{
            [geoCoder reverseGeocodeLocation:userLoc
                           completionHandler:^(NSArray *placemarks, NSError *error) {
                               CLPlacemark *placemark = [placemarks objectAtIndex:0];
                               if (placemark) {
                                   if(placemark.thoroughfare){
                                       NSLog(@" PLACEMARK :  %@",placemark.thoroughfare);
                                   }
                               }
                               [[_FIRDbRef child:@"users"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                                   NSDictionary *dictData = snapshot.value;
                                   NSLog(@"Retrieved Dictionary Data : %@",dictData);
                                   FIRDatabaseQuery *query = [_FIRDbRef child:@"users"];
                                   [query observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                                       //removing overalys
                                       [_mapView removeOverlays: [_mapView overlays]];
                                       int count = 0;
                                       for (FIRDataSnapshot *child in snapshot.children) {
                                           double lat = [child.value[@"latitude"] doubleValue];
                                           double lon = [child.value[@"longitude"] doubleValue];
                                           newLocation = [[CLLocation alloc]initWithLatitude:lat longitude:lon];
                                           int distance = [newLocation distanceFromLocation:userLoc];
                                           NSLog(@"DISTANCE %d", distance);
                                           if(distance >0 && distance <10000){
                                               if ([child.value[@"endLocation"] isEqual: placemark.thoroughfare]) {
                                                   count++;
                                               }
                                                   if(count > 1){
                                                       NSString *strType = [[NSString alloc] initWithFormat:@"%@", child.value[@"type"]];
                                                       NSString *strLat = [[NSString alloc] initWithFormat:@"%f", lat];
                                                       NSLog(@"%@",strLat);
                                                       NSString *strLon = [[NSString alloc] initWithFormat:@"%f", lon];
                                                       NSMutableDictionary *dictOverlayDetails = [[NSMutableDictionary alloc]init];
                                                       [dictOverlayDetails setValue:strType forKey:@"type"];
                                                       [dictOverlayDetails setValue:strLat forKey:@"latitude"];
                                                       [dictOverlayDetails setValue:strLon forKey:@"longitude"];
                                                       [arrOverlayDetails addObject:dictOverlayDetails];
                                                       // adding circle overlay
                                                       MKCircle *circleForUserLoc = [MKCircle circleWithCenterCoordinate:newLocation.coordinate radius:50];
                                                       [_mapView addOverlay:circleForUserLoc];
                                                       
                                                  }
                                             // }
                                           }
                                       }
                                   }];
                               }];
                           }
             ];
        });
    }
}

- (IBAction)homeButtonClicked:(UIButton *)sender{
    [_segmentedControl setHidden:NO];
    [_homeButton setHidden: YES];
    [_yourLocationButton setHidden:YES];
    [locManager startUpdatingLocation];
    [_mapView removeOverlays: [_mapView overlays]];
}

- (IBAction)yourLocationClicked:(UIButton *)sender {
    MKCoordinateRegion mapRegion;
    mapRegion.center = _mapView.userLocation.coordinate;//setting mapview centre as userlocation coordinates
    mapRegion.span.latitudeDelta = 0.01;
    mapRegion.span.longitudeDelta = 0.01;
    [_mapView setRegion:mapRegion animated: YES];//setting mapview region as userlocation region
    
}

#pragma mark - Custom Method

-(void)addCircle:(CLLocation *)location{
    //add annotation
    MKPointAnnotation *anno = [[MKPointAnnotation alloc] init];
    anno.coordinate = location.coordinate;
    [_mapView addAnnotation:anno];
    
    //add overlay
    [_mapView addOverlay:[MKCircle circleWithCenterCoordinate:location.coordinate radius:100]];
    
    //zoom into the location with the defined circle at the middle
    [self zoomInto:location.coordinate distance:(100 * 4.0) animated:YES];
}

-(void)zoomInto:(CLLocationCoordinate2D)zoomLocation distance:(CGFloat)distance animated:(BOOL)animated{
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, distance, distance);
    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
    [_mapView setRegion:adjustedRegion animated:animated];
}

-(void)locDetails:(NSString *)title :(void (^)(NSDictionary *dict, NSError *error)) completionBlock{
    NSError *error;
    if(!(latitude == Nil || longitude == Nil || strIdentifier == Nil)){
        if (arrLocations.count > 3) {
        dictReturn = [[NSDictionary alloc]init];
        arrCount = arrLocations.count;
        dictReturn = @{@"UDID":strIdentifier,@"Type":title,@"StartLocation":[arrLocations objectAtIndex:arrLocations.count-3],@"EndLocation":[arrLocations lastObject], @"Latitude":latitude, @"Longitude":longitude};
        NSLog(@"Detail Dictionary : %@",dictReturn);
        completionBlock(dictReturn,error);
        }
    }
}


@end
