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
    NSString* strIdentifier;
    NSString *strAnnotationTitle;
    NSString *strSegmentTitle;
    NSDictionary *dictUserLoc;
    NSDictionary *dictLocDetails;
    NSMutableArray *arrOverlayDetails;
    NSNumber *latitude;
    NSNumber *longitude;
    MKCircleRenderer *circleRenderer;
    CLGeocoder *geoCoder;
    UIActivityIndicatorView *activityIndicator;
    UIView *indicatorView;
    BOOL isKeyNull;
    __block NSDictionary *dictReturn;
    __block FIRDataSnapshot *datasnapshot;
}

@end

@implementation TrafficViewController

#pragma mark - View Cycles

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //Notification for background execution
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(pauseApp:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    //Notification for foreground execution
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(playApp:)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
    
    //Initialisation
    geoCoder = [[CLGeocoder alloc]init];
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
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        UIFont *font = [UIFont boldSystemFontOfSize:25.0f];
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
                                                               forKey:NSFontAttributeName];
        [_segmentedControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
    }else{
        UIFont *font = [UIFont boldSystemFontOfSize:15.0f];
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:font
                                                               forKey:NSFontAttributeName];
        [_segmentedControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
    }
    
    //Setting mapview type
    _mapView.mapType = MKMapTypeStandard;
    
    //Retrieve device unique ID
    strIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    self.FIRDbRef = [[FIRDatabase database] reference];
    _mapView.showsUserLocation = YES;
    self.FIRDbRef = [[FIRDatabase database] reference];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
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
    });
    return circleView ;
}

#pragma  mark - Core location delegate methods

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
    [_mapView setRegion:MKCoordinateRegionMake(newLoc.coordinate, MKCoordinateSpanMake(0.01, 0.01)) animated:NO]; //setting mapview region as userlocation region
    userLoc = [[CLLocation alloc]initWithLatitude:newLoc.coordinate.latitude longitude:newLoc.coordinate.longitude];
    NSNumber *userlat = [NSNumber numberWithDouble:userLoc.coordinate.latitude];
    NSNumber *userlon = [NSNumber numberWithDouble:userLoc.coordinate.longitude];
    NSDictionary *userLocation=@{@"userlat":userlat,@"userlon":userlon};
    
    [[NSUserDefaults standardUserDefaults] setObject:userLocation forKey:@"userLocation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self drawOverlay:userLoc];
}

#pragma mark - IB Action

- (IBAction)segmentedControlClicked:(id)sender {
    NSInteger intSelectedSegment = _segmentedControl.selectedSegmentIndex;
    strSegmentTitle = [_segmentedControl titleForSegmentAtIndex:_segmentedControl.selectedSegmentIndex];
    if(intSelectedSegment == 0){
        // SLOW MOVING CLICKED
        [self showAlertConfirmation:strSegmentTitle];
    }else if (intSelectedSegment == 1){
        // FREE MOVING CLICKED
        [self showAlertConfirmation:strSegmentTitle];
    }else if (intSelectedSegment == 2){
        // BLOCK CLICKED
        [self showAlertConfirmation:strSegmentTitle];
    }
}

- (IBAction)btnStreetViewClicked:(id)sender {
    [locManager stopUpdatingLocation];
}

- (IBAction)btnRefreshClicked:(id)sender {
    [locManager startUpdatingLocation];
    [self drawOverlay:[self RetrieveLocFromUserDefaults]];
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

-(void)drawOverlay:(CLLocation *)loc{
    //removing overalys
    [_mapView removeOverlays: [_mapView overlays]];
    FIRDatabaseQuery *query = [_FIRDbRef child:@"users"];
    [query observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        dispatch_async(dispatch_get_main_queue(), ^{
            datasnapshot = snapshot;
            [self getOverlays:loc];
        });
    }];
}

-(void)addDataToFirebase:(NSString *)title{
    [[[_FIRDbRef child:@"users"] child:[dictLocDetails valueForKey:@"UDID"]] setValue:@{@"type": title,@"endLocation":[dictLocDetails valueForKey:@"EndLocation"], @"latitude": [dictLocDetails valueForKey:@"Latitude"], @"longitude":[dictLocDetails valueForKey:@"Longitude"], @"date": [dictLocDetails valueForKey:@"Date"]}withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
        NSLog(@"FIRDatabase Reference :%@", ref);
    }];
}

-(void)showAlertConfirmation:(NSString *)segmentTitle{
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
                [self addDataToFirebase:segmentTitle];
            }
            [self drawOverlay:[self RetrieveLocFromUserDefaults]];
        }];
    }];
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:Nil];
    [alert addAction:okButton];
    [alert addAction:cancelButton];
    [self presentViewController:alert animated:YES completion:Nil];
}

-(void)locDetails:(NSString *)title :(void (^)(NSDictionary *dict, NSError *error)) completionBlock{
    __block NSError *err;
    if(!(latitude == Nil || longitude == Nil || strIdentifier == Nil)){
        dictReturn = [[NSDictionary alloc]init];
        [geoCoder reverseGeocodeLocation:userLoc
                       completionHandler:^(NSArray *placemarks, NSError *error) {
                           CLPlacemark *placemark = [placemarks objectAtIndex:0];
                           if(placemark) {
                               if(placemark.thoroughfare){
                                   NSLog(@" PLACEMARK :  %@",placemark.thoroughfare);
                                   dictReturn = @{@"UDID":strIdentifier,@"Type":title,@"EndLocation":placemark.thoroughfare, @"Latitude":latitude, @"Longitude":longitude, @"Date":[NSString stringWithFormat:@"%@",[NSDate date]]};
                                   NSLog(@"Detail Dictionary : %@",dictReturn);
                                   completionBlock(dictReturn,err);
                               }
                           }
                       }];
    }
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

-(void)pauseApp:(NSNotification*)theNotification{
    [_mapView removeOverlays:_mapView.overlays];
}

-(void)playApp:(NSNotification*)theNotification{
    [locManager startUpdatingLocation];
    NSDictionary *userLocdict=[[NSUserDefaults standardUserDefaults] objectForKey:@"userLocation"];
    CLLocation *tempLoc = [[CLLocation alloc]initWithLatitude:[[userLocdict objectForKey:@"uselat"]doubleValue] longitude:[[userLocdict objectForKey:@"userlon"]doubleValue]];
    [self getOverlays:tempLoc];
}

-(void)getOverlays:(CLLocation *)location{
    for (FIRDataSnapshot *child in datasnapshot.children) {
        double lat = [child.value[@"latitude"] doubleValue];
        double lon = [child.value[@"longitude"] doubleValue];
        CLLocation *newLocation = [[CLLocation alloc]initWithLatitude:lat longitude:lon];
        int distance = [newLocation distanceFromLocation:location];
        NSLog(@"DISTANCE %d", distance);
        if(distance >100 && distance <10000){
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
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // adding circle overlay
                    MKCircle *circleForUserLoc = [MKCircle circleWithCenterCoordinate:newLocation.coordinate radius:50];
                    [_mapView addOverlay:circleForUserLoc];
                });
            }
        }
    }
}

-(CLLocation *)RetrieveLocFromUserDefaults{
    NSDictionary *userLocdict=[[NSUserDefaults standardUserDefaults] objectForKey:@"userLocation"];
    CLLocation *tempLoc = [[CLLocation alloc]initWithLatitude:[[userLocdict objectForKey:@"uselat"]doubleValue] longitude:[[userLocdict objectForKey:@"userlon"]doubleValue]];
    return tempLoc;
}
@end
