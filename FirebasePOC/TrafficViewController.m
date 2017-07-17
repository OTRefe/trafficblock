//
//  ViewController.m
//  FirebasePOC
//
//  Created by Ann Mac on 03/07/17.
//  Copyright © 2017 MACMINI 2. All rights reserved.
//

#import "TrafficViewController.h"

@interface TrafficViewController (){
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
    UIActivityIndicatorView *activityIndicator;
    UIView *indicatorView;
    BOOL isKeyNull;
    __block NSDictionary *dictReturn;
}

@end

@implementation TrafficViewController

#pragma mark - View Cycles

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //Initialisation
    geoCoder = [[CLGeocoder alloc]init];
    arrLocations = [[NSMutableArray alloc]init];
    arrOverlayDetails = [[NSMutableArray alloc]init];
    locManager = [[CLLocationManager alloc]init];
    
    locManager.delegate = self;
    [locManager requestWhenInUseAuthorization];
    [locManager requestAlwaysAuthorization];
    [locManager startUpdatingLocation];
    
    _mapView.delegate = self;
    _mapView.showsUserLocation = YES;
    
    //Customizing segmented control
    NSArray *arrSegments = [_segmentedControl subviews];
    // Change the tintColor of each subview within the array:
    [[arrSegments objectAtIndex:2] setBackgroundColor:[UIColor orangeColor]];
    [[arrSegments objectAtIndex:1] setBackgroundColor:[UIColor colorWithRed:0 green:255 blue:0 alpha:1]];
    [[arrSegments objectAtIndex:0] setBackgroundColor:[UIColor redColor]];

    //Setting mapview type
    _mapView.mapType = MKMapTypeStandard;
    
    //Retrieve device unique ID
    strIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];

    self.FIRDbRef = [[FIRDatabase database] reference];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self drawOverlay];
}

#pragma  mark - Mapview delegate methods

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
            }else if ([type isEqualToString:@"Block"]){
                circleView.imageView.image = [UIImage imageNamed:@"red circle"];
            }else if ([type isEqualToString:@"Free Moving"]){
                circleView.imageView.image = [UIImage imageNamed:@"green circle"];
            }
        }
    }
    return circleView ;
}

#pragma  mark - Mapview delegate methods

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLoc fromLocation:(CLLocation *)oldLocation{
    
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
    [_mapView setRegion:MKCoordinateRegionMake(newLoc.coordinate, MKCoordinateSpanMake(0.01, 0.01)) animated:NO]; //setting mapview region as userlocation region
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
                   }];
}

#pragma mark - IB Action

- (IBAction)segmentedControlClicked:(id)sender {
    NSInteger intSelectedSegment = _segmentedControl.selectedSegmentIndex;
    strSegmentTitle = [_segmentedControl titleForSegmentAtIndex:_segmentedControl.selectedSegmentIndex];
    if(intSelectedSegment == 0){
        // SLOW MOVING CLICKED
        [self showAlert:strSegmentTitle];
    }else if (intSelectedSegment == 1){
        // FREE MOVING CLICKED
        [self showAlert:strSegmentTitle];
    }else if (intSelectedSegment == 2){
        // BLOCK CLICKED
        [self showAlert:strSegmentTitle];
    }
}

- (IBAction)btnStreetViewClicked:(id)sender {
    [locManager stopUpdatingLocation];
}

- (IBAction)btnRefreshClicked:(id)sender {
    [locManager startUpdatingLocation];
    [self drawOverlay];
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"ARViewSegue"]){
        ARViewController *arViewController = segue.destinationViewController;
        NSLog(@"Array Overlay Details : %@", arrOverlayDetails);
        arViewController.arrPoints = arrOverlayDetails;
    }
}

#pragma mark - Custom Methods

-(void)addCircle:(CLLocation *)location{
    //add annotation
    MKPointAnnotation *anno = [[MKPointAnnotation alloc] init];
    anno.coordinate = location.coordinate;
    [_mapView addAnnotation:anno];

    //add overlay
    [_mapView addOverlay:[MKCircle circleWithCenterCoordinate:location.coordinate radius:50]];
    
    //zoom into the location with the defined circle at the middle
    [self zoomInto:location.coordinate distance:(50 * 4.0) animated:YES];
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
            dictReturn = @{@"UDID":strIdentifier,@"Type":title,@"StartLocation":[arrLocations objectAtIndex:arrLocations.count-3],@"EndLocation":[arrLocations lastObject], @"Latitude":latitude, @"Longitude":longitude, @"Date":[NSString stringWithFormat:@"%@",[NSDate date]]};
        NSLog(@"Detail Dictionary : %@",dictReturn);
        completionBlock(dictReturn,error);
        }
    }
}

-(void)drawOverlay{
    //removing overalys
    [_mapView removeOverlays: [_mapView overlays]];
    
    [geoCoder reverseGeocodeLocation:userLoc
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       CLPlacemark *placemark = [placemarks objectAtIndex:0];
                       if (placemark) {
                           if(placemark.thoroughfare){
                               NSLog(@" PLACEMARK :  %@",placemark.thoroughfare);
                           }
                       }
                   }];
    [[_FIRDbRef child:@"users"] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        [self showActivityIndicator];
        NSDictionary *dictData = snapshot.value;
        NSLog(@"Retrieved Dictionary Data : %@",dictData);
        FIRDatabaseQuery *query = [_FIRDbRef child:@"users"];
        [query observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
            //removing overalys
            [_mapView removeOverlays: [_mapView overlays]];
            
            for (FIRDataSnapshot *child in snapshot.children) {
                double lat = [child.value[@"latitude"] doubleValue];
                double lon = [child.value[@"longitude"] doubleValue];
                newLocation = [[CLLocation alloc]initWithLatitude:lat longitude:lon];
                int distance = [newLocation distanceFromLocation:userLoc];
                NSLog(@"DISTANCE %d", distance);
                if(distance >0 && distance <10000){
                    //gets users current date
                    NSDate *currentDate = [NSDate date];
                    //date formatting
                    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss +0000"];
                    NSDate *date = [dateFormatter dateFromString:child.value[@"date"]];
                    NSTimeInterval secondsBetween = [currentDate timeIntervalSinceDate:date];
                    // 1800 = 30mins*60sec
                    if (secondsBetween > 1800) {
                        NSString *strType = [[NSString alloc] initWithFormat:@"%@", child.value[@"type"]];
                        NSString *strLat = [[NSString alloc] initWithFormat:@"%f", lat];
                        NSString *strLon = [[NSString alloc] initWithFormat:@"%f", lon];
                        NSString *strDistance = [[NSString alloc]initWithFormat:@"%d",distance];
                        
                        NSMutableDictionary *dictOverlayDetails = [[NSMutableDictionary alloc]init];
                        [dictOverlayDetails setValue:strType forKey:@"type"];
                        [dictOverlayDetails setValue:strLat forKey:@"latitude"];
                        [dictOverlayDetails setValue:strLon forKey:@"longitude"];
                        [dictOverlayDetails setValue:strDistance forKey:@"distance"];
                        [dictOverlayDetails setValue:child.value[@"endLocation"] forKey:@"placemark"];
                        [arrOverlayDetails addObject:dictOverlayDetails];
                        
                        // adding circle overlay
                        MKCircle *circleForUserLoc = [MKCircle circleWithCenterCoordinate:newLocation.coordinate radius:50];
                        [_mapView addOverlay:circleForUserLoc];
                    }
                }
            }
            [self hideActivityIndicator];
        }];
    }];
}

-(void)addDataToFirebase:(NSString *)title{
    [[[_FIRDbRef child:@"users"] child:[dictLocDetails valueForKey:@"UDID"]] setValue:@{@"type": title ,@"startLocation":[dictLocDetails valueForKey:@"StartLocation"],@"endLocation":[dictLocDetails valueForKey:@"EndLocation"], @"latitude": [dictLocDetails valueForKey:@"Latitude"], @"longitude":[dictLocDetails valueForKey:@"Longitude"], @"date": [dictLocDetails valueForKey:@"Date"]}withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        NSLog(@"FIRDatabase Reference :%@", ref);
        [self hideActivityIndicator];
    }];
}

-(void)showAlert:(NSString *)segmentTitle{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmation" message:@"Do you want to update traffic status" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [self locDetails:strSegmentTitle :^(NSDictionary *dict,NSError *error){
            dictLocDetails = dict;
            NSArray *keys = [dictLocDetails allKeys];
            NSLog(@"Keys : %@", keys);
            isKeyNull = false;
            [dictLocDetails enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop){
                if([object isEqual:NULL]){
                    stop = false;
                    isKeyNull = true;
                }
            }];
            if(!isKeyNull){
                [self showActivityIndicator];
                [self addDataToFirebase:segmentTitle];
            }
            [self drawOverlay];
        }];
    }];
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:Nil];
    [alert addAction:okButton];
    [alert addAction:cancelButton];
    [self presentViewController:alert animated:YES completion:Nil];
}

-(void)showActivityIndicator{
    indicatorView = [[UIView alloc]initWithFrame:self.view.bounds];
    indicatorView.backgroundColor = [UIColor colorWithRed:0/255 green:0/255 blue:0/255 alpha:0.6];
    [self.view addSubview:indicatorView];
    activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityIndicator setBackgroundColor:[UIColor clearColor]];
    activityIndicator.alpha = 1.0;
    activityIndicator.center = self.view.center;
    [activityIndicator startAnimating];
    [indicatorView addSubview:activityIndicator];
}

-(void)hideActivityIndicator{
    [indicatorView removeFromSuperview];
}
@end
