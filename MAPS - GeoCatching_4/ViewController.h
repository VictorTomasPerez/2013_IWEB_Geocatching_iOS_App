//
//  ViewController.h
//  MAPS - GeoCatching_4
//
//  Created by Víctor Tomás Pérez on 04/12/13.
//  Copyright (c) 2013 Victor_Tomas_Perez. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MapKit/MapKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>

@interface ViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@end
