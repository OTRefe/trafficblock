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

    [locManager startUpdatingLocation];
    
    //Setting mapview type
    _mapView.mapType = MKMapTypeStandard;
    //Retrieve device unique ID
    strIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];

    self.FIRDbRef = [[FIRDatabase database] reference];
    _mapView.showsTraffic = YES;
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
    view.image = [UIImage imageNamed:@"pin"];
    view.annotation = annotation;
    return view;
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    
    
    circleRenderer = [[MKCircleRenderer alloc]initWithOverlay:overlay];
    circleRenderer.strokeColor = [UIColor blackColor];
    circleRenderer.lineWidth = 2;
    [[_FIRDbRef child:@"users"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        NSDictionary *dictData = snapshot.value;
        //NSLog(@"Retrieved Dictionary Data : %@",dictData);
        FIRDatabaseQuery *query = [_FIRDbRef child:@"users"];
        [query observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            for (FIRDataSnapshot *child in snapshot.children) {
                if ([child.value[@"type"] isEqualToString:@"Slow Moving"]) {
                  //  circleRenderer.fillColor = [UIColor colorWithDisplayP3Red:135/255 green:206/255 blue:250/255 alpha:0.8];
                    circleRenderer.fillColor = [UIColor blueColor];
                    NSLog(@"Slow Moving");
                }else if ([child.value[@"type"] isEqualToString:@"Block"]){
                    circleRenderer.fillColor = [UIColor colorWithDisplayP3Red:255/255 green:0/255 blue:0/255 alpha:0.4];
                    NSLog(@"Block");
                }else if ([child.value[@"type"] isEqualToString:@"Free Moving"]){
                   // circleRenderer.fillColor = [UIColor colorWithDisplayP3Red:224/255 green:255/255 blue:255/255 alpha:0.8];
                    circleRenderer.fillColor = [UIColor greenColor];
                    NSLog(@"Free Moving");
                }
            }
        }];
    }];
    return  circleRenderer;
    
}

#pragma  mark - Mapview delegate methods

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLoc fromLocation:(CLLocation *)oldLocation{

    latitude = [NSNumber numberWithDouble:newLoc.coordinate.latitude];//userlocation latitude
    longitude = [NSNumber numberWithDouble:newLoc.coordinate.longitude];//userlocation longtitude
    for (id annotation in _mapView.annotations){
        [_mapView removeAnnotation:annotation];
    }
    MKCoordinateRegion mapRegion;
    mapRegion.center = newLoc.coordinate;//setting mapview centre as userlocation coordinates
    mapRegion.span.latitudeDelta = 0.01;
    mapRegion.span.longitudeDelta = 0.01;
    [_mapView setRegion:mapRegion animated: YES];//setting mapview region as userlocation region
    
    userLoc = [[CLLocation alloc]initWithLatitude:newLoc.coordinate.latitude longitude:newLoc.coordinate.longitude];
    [geoCoder reverseGeocodeLocation:userLoc
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       CLPlacemark *placemark = [placemarks objectAtIndex:0];
                       if(placemark) {
                           if(placemark.thoroughfare){
                            //   //NSLog(@" PLACEMARK :  %@",placemark.thoroughfare);
                               [arrLocations addObject:placemark.thoroughfare];
                            //   //NSLog(@"Location Array %@",arrLocations);
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
        [self locDetails:strSegmentTitle :^(NSDictionary *dict,NSError *error) {
            dictLocDetails = dict;
            NSArray *keys = [dictLocDetails allKeys];
       //     //NSLog(@"Keys : %@", keys);
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
        [self locDetails:strSegmentTitle :^(NSDictionary *dict,NSError *error) {
            dictLocDetails = dict;
            NSArray *keys = [dictLocDetails allKeys];
         //   //NSLog(@"Keys : %@", keys);
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
        [self locDetails:strSegmentTitle :^(NSDictionary *dict,NSError *error) {
            dictLocDetails = dict;
            NSArray *keys = [dictLocDetails allKeys];
          //  //NSLog(@"Keys : %@", keys);
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
       // [locManager stopUpdatingLocation];
        dispatch_async(dispatch_get_main_queue(), ^{
            [geoCoder reverseGeocodeLocation:userLoc
                           completionHandler:^(NSArray *placemarks, NSError *error) {
                               CLPlacemark *placemark = [placemarks objectAtIndex:0];
                               if (placemark) {
                                   if(placemark.thoroughfare){
                                     //  //NSLog(@" PLACEMARK :  %@",placemark.thoroughfare);
                                   }
                               }
                               [[_FIRDbRef child:@"users"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                                   NSDictionary *dictData = snapshot.value;
                                   ////NSLog(@"Retrieved Dictionary Data : %@",dictData);
                                   FIRDatabaseQuery *query = [_FIRDbRef child:@"users"];
                                   [query observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                                       //removing overalys
                                       [_mapView removeOverlays: [_mapView overlays]];
                                   //    int count;
                                       for (FIRDataSnapshot *child in snapshot.children) {
                                           double lat = [child.value[@"latitude"] doubleValue];
                                       //    //NSLog(@"double lat %f", lat);
                                           double lon = [child.value[@"longitude"] doubleValue];
                                       //    //NSLog(@"double lon %f", lon);
                                           newLocation = [[CLLocation alloc]initWithLatitude:lat longitude:lon];
                                           int distance = [newLocation distanceFromLocation:userLoc];
                                       //    //NSLog(@"DISTANCE %d", distance);
                                           if(distance >0 && distance <10000){
//                                               if ([child.value[@"endLocation"] isEqual: placemark.thoroughfare]) {
//                                                   count++;
//                                               }
                                               MKCircle *circleForUserLoc = [MKCircle circleWithCenterCoordinate:newLocation.coordinate radius:100];
                                             //  //NSLog(@"Added overlay");
                                               [_mapView addOverlay:circleForUserLoc];

                                           }
                                           
                                       }
                                       //if(count > 2){
                                           //adding circle overlay
//                                           MKCircle *circleForUserLoc = [MKCircle circleWithCenterCoordinate:newLocation.coordinate radius:100];
//                                           //NSLog(@"Added overlay");
//                                           [_mapView addOverlay:circleForUserLoc];
                                     //  }
                                    //   [locManager startUpdatingLocation];
                                   }];
                               }];
                           }
             ];
        });
    }
}

#pragma mark - Custom Method

-(void)locDetails:(NSString *)title :(void (^)(NSDictionary *dict, NSError *error)) completionBlock{
    NSError *error;
    if(!(latitude == Nil || longitude == Nil || strIdentifier == Nil)){
        if (arrLocations.count > 3) {
        dictReturn = [[NSDictionary alloc]init];
        arrCount = arrLocations.count;
        dictReturn = @{@"UDID":strIdentifier,@"Type":title,@"StartLocation":[arrLocations objectAtIndex:arrLocations.count-3],@"EndLocation":[arrLocations lastObject], @"Latitude":latitude, @"Longitude":longitude};
        //NSLog(@"Detail Dictionary : %@",dictReturn);
        completionBlock(dictReturn,error);
        }
    }
}

@end
