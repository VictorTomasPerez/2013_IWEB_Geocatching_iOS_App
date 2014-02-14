//
//  ViewController.m
//  MAPS - GeoCatching_4
//
//  Created by Víctor Tomás Pérez on 04/12/13.
//  Copyright (c) 2013 Victor_Tomas_Perez. All rights reserved.
//

#import "ViewController.h"
#import "CrumbPath.h"
#import "CrumbPathView.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <math.h>

// Radio de la Tierra en metros (para la formula del calculo de distancia entre dos coordenadas)
const float EARTH_RADIUS = 6353;

// Umbrales de distancia entre el punto actual y el punto mas cercano a un ANNOTATION (en metros)
const float LARGE_THRESHOLD = 50;
const float MEDIUM_THRESHOLD = 30;
const float SHORT_THRESHOLD = 15;

const float ITEM_THRESHOLD = 5;
const float INITIAL_THRESHOLD = 10000000000;


@interface ViewController ()

@property (nonatomic, strong) AVAudioPlayer *audioPlayer1;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer2;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer3;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer4;

@property (strong, nonatomic) IBOutlet UILabel *distanceLabelMeters;
@property (strong, nonatomic) IBOutlet UILabel *nombreItemLabel;

@property (strong, nonatomic) IBOutlet UILabel *warningLabel1;
@property (strong, nonatomic) IBOutlet UILabel *warningLabel2;
@property (strong, nonatomic) IBOutlet UIButton *botonBorrar;

@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIView *backgroundWhiteView;
@property (strong, nonatomic) IBOutlet UIView *backgroundYellowView;
@property (strong, nonatomic) IBOutlet UIView *backgroundOptinsView;

@property (strong, nonatomic) IBOutlet UITextField *itemNameTextField;

@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, strong) CrumbPath *crumbs;
@property (nonatomic, strong) CrumbPathView *crumbView;

@property (nonatomic, strong) NSMutableArray *annotations;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // REDONDEAMOS LOS BORDES DE LA VISTA DEL MAPA Y EL RESTO DE VISTAS
    self.mapView.layer.cornerRadius = 10;
    self.mapView.layer.masksToBounds = YES;
    
    self.backgroundWhiteView.layer.cornerRadius = 10;
    self.backgroundWhiteView.layer.masksToBounds = YES;
    
    self.backgroundYellowView.layer.cornerRadius = 10;
    self.backgroundYellowView.layer.masksToBounds = YES;
    
    self.warningLabel1.layer.cornerRadius = 10;
    self.warningLabel1.layer.masksToBounds = YES;
    
    self.warningLabel2.layer.cornerRadius = 10;
    self.warningLabel2.layer.masksToBounds = YES;
    
    self.backgroundOptinsView.layer.cornerRadius = 10;
    self.backgroundOptinsView.layer.masksToBounds = YES;
    
    // DEFINIMOS LAS PISTAS DE AUDIO A EMPLEAR EN LA APP
	NSURL *url1 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Hero" ofType:@"aiff"]];
    _audioPlayer1 = [[AVAudioPlayer alloc] initWithContentsOfURL:url1 error:nil];
    self.audioPlayer1.numberOfLoops = -1;
    
	NSURL *url2 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Siren" ofType:@"aif"]];
    _audioPlayer2 = [[AVAudioPlayer alloc] initWithContentsOfURL:url2 error:nil];
    self.audioPlayer2.numberOfLoops = -1;
    
	NSURL *url3 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Siren_WooWoo" ofType:@"aif"]];
    _audioPlayer3 = [[AVAudioPlayer alloc] initWithContentsOfURL:url3 error:nil];
    self.audioPlayer3.numberOfLoops = -1;

   	NSURL *url4 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"itemFounded" ofType:@"aiff"]];
    _audioPlayer4 = [[AVAudioPlayer alloc] initWithContentsOfURL:url4 error:nil];
    self.audioPlayer4.numberOfLoops = -1;
    
    // INICIALIZAMOS EL LOCATION MANAGER Y LO CONFIGURAMOS
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
	self.locationManager.desiredAccuracy =kCLLocationAccuracyBestForNavigation;
    
    [self.locationManager startUpdatingLocation];
    
    // INICIALIZAMOS EL LONG PRESS GESTURE RECOGNIZER Y LO CONFIGURAMOS
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]init];
    
    self.longPressGestureRecognizer.minimumPressDuration = 1.0;
    
    [self.mapView addGestureRecognizer:self.longPressGestureRecognizer];
    
    // INICIALIZAMOS, DESCARGAMOS DE LA BBDD Y CONFIGURAMOS LAS ANNOTATIONS
    self.annotations = [[NSMutableArray alloc] init];
    
    // DESCARGA DE LA BBDD EN parse.com LAS ANNOTATIONS GUARDADAS EN LAS ANTERIORES EJECUCIONES.
    // DASHBOARD/DATA_BROWSER BBDD www.parse.com -> https://www.parse.com/apps/geocatching-iweb/collections
    PFQuery *query = [PFQuery queryWithClassName:@"Location"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if(!error)
        {
            NSString *nombreItem;
            PFGeoPoint *geoPointAnnotation = [[PFGeoPoint alloc] init];
            
            for (int aux = 0; aux < objects.count; aux++)
            {
                nombreItem = [objects[aux] objectForKey:@"title"];
                geoPointAnnotation = [objects[aux] objectForKey:@"location"];
                
                MKPointAnnotation *newAnnotation = [[MKPointAnnotation alloc]init];
                
                CLLocationCoordinate2D pinCoordinate;
                
                pinCoordinate.latitude = geoPointAnnotation.latitude;
                pinCoordinate.longitude = geoPointAnnotation.longitude;
                
                newAnnotation.coordinate = pinCoordinate;
                newAnnotation.title = nombreItem;
                
                [self.annotations addObject:newAnnotation];
            }
        }
    }];
}

// TRAS CARGAR EL MAPA, CARGAMOS SOBRE EL LO DEMAS
- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
    self.mapView.showsUserLocation = YES;
    [self.mapView addAnnotations:self.annotations];

}

// SI SE REALIZA UN LONG PRESS GESTURE RECOGNIZER SOBRE EL MAPVIEW, SE GUARDARA EN LA BBDD Y LOCALMENTE (APARECERA EN EL MAPA)
// UNA NUEVA ANNOTATION, DONDE SE ENCONTRARA UN ITEM ESCONDIDO.
- (IBAction)longPress:(UILongPressGestureRecognizer*)sender
{
    if (sender.state != UIGestureRecognizerStateEnded){
        return;
    }
    
    CGPoint touchPoint = [sender locationInView:self.mapView];
    
    CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    MKPointAnnotation *newAnnotation = [[MKPointAnnotation alloc]init];
    
    newAnnotation.coordinate = touchMapCoordinate;
    newAnnotation.title = self.itemNameTextField.text;
    
    // GUARDAMOS LOCALMENTE Y DIBUJAMOS
    [self.mapView addAnnotation:newAnnotation];
    [self.annotations addObject:newAnnotation];
    
    // GUARDAMOS EN LA BASE DE DATOS LA ANNOTATION NUEVA (parse.com):
    PFGeoPoint *geoPointAnnotation = [[PFGeoPoint alloc] init];

    geoPointAnnotation = [PFGeoPoint geoPointWithLatitude:newAnnotation.coordinate.latitude
                                                longitude:newAnnotation.coordinate.longitude];
    
    PFObject *object = [PFObject objectWithClassName:@"Location"];
    
    [object setObject:newAnnotation.title forKey:@"title"];
    [object setObject:geoPointAnnotation forKey:@"location"];
    [object saveEventually];
    
    NSLog(@"--------------------------------------------------------------------------------");
    NSLog(@"-----> Ha annadido un nuevo item con nombre->%@ y coordenadas->Latitud: %f / Longitud: %f", newAnnotation.title, newAnnotation.coordinate.latitude, newAnnotation.coordinate.longitude);
    NSLog(@"--------------------------------------------------------------------------------");

    
    // PINTAMOS EN CONSOLA LA LISTA DE ANNOTATIONS TOTAL
    int counter = 0;
    
    NSLog(@"Lista de los items almacenados:\n");

    for (MKPointAnnotation *obj in self.annotations)
    {
        counter ++;
        
        NSLog(@"-----> Ítem nº %i.-Nombre->%@; Coordenadas->Latitud: %f / Longitud: %f", counter, obj.title, obj.coordinate.latitude, obj.coordinate.longitude);
    }
}

- (void)dealloc
{
    self.locationManager.delegate = nil;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - MapKit

// CADA VEZ QUE SE REALIZA UNA ACTUALIZACION DE POSCION, SE CALCULA LA DISTANCIA CON EL ANNOTATION MAS CERCANO, Y DEPENDIENDO
// DE LOS UMBRALES (CONSTANTES) CONFIGURADOS AL COMIENZO DE ESTE FICHERO, SE MOSTRARAN DISNTINTOS AVISOS TANTO GRAFICOS COMO
// SONOROS. ADEMAS, PINTA LA TRAYECTORIA DEL USUARIO CON LA AYUDA DE LAS CLASES TOMADAS DE APPLE "CrumbPath" y "CrumbPathView"
// MEDIANTE OVERLAY
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    if (newLocation)
    {
        // EL ALGORITMO DE DISTANCIA NO PARECE MUY PRECISO (MEJORA).
        // TAMBIEN FALLA QUE AL EMPEZAR, PINTA UNA LINEA MUY LARGA (MEJORA).
        // AL HACER UN NUEVO ANNOTATION; SE QUEDA UN POCO PILLADO. VER SI SE PUEDE USAR
        // GCP CON THREADS (MEJORA).
        
        // ALGORITMO DEL CALCULO DE LA DISTANCIA ENTRE USUARIO Y ANNOTATION MAS CERCANO DE TODOS
        float distance = INITIAL_THRESHOLD;
        float distanceAux;
        NSString *nombreItemCercano;
        
        float userLatitude = newLocation.coordinate.latitude;
        float userLongitude = newLocation.coordinate.longitude;
        
        for (MKPointAnnotation *obj in self.annotations){
            float annotationLatitude = obj.coordinate.latitude;
            float annotationLongitude = obj.coordinate.longitude;
            
            distanceAux = acosf(sinf(userLatitude)*sinf(annotationLatitude)+
                             cosf(userLatitude)*cosf(annotationLatitude)*
                             cosf(userLongitude-annotationLongitude)) * EARTH_RADIUS;
            
            // COGE LA DISTANCIA MINIMA DE TODOS LOS ANNOTATIONS
            if(distanceAux < distance){
                nombreItemCercano = obj.title;
                distance = distanceAux;
            }
        }
        
        // ACTUALIZACION DE ELEMENTOS GRAFICOS Y SONOROS DEPENDIENDO DE DICHA DISTANCIA
        NSString *itm = [[NSString alloc] initWithFormat:@"Distancia al item %@: ", nombreItemCercano];
        
        if(self.annotations.count != 0)
        {
            self.nombreItemLabel.text =itm;
            
            NSLog(@"-----> Distancia al item %@: %f", nombreItemCercano, distance);
       
        } else {
            self.nombreItemLabel.text =@"Distancia al item:";
        }

        if (MEDIUM_THRESHOLD<distance && distance<LARGE_THRESHOLD)
        {
            self.warningLabel1.text = @"LEJOS";
            self.warningLabel2.text = @"LEJOS";
            self.warningLabel1.backgroundColor = [UIColor redColor];
            self.warningLabel2.backgroundColor = [UIColor redColor];
            
            [self.audioPlayer1 prepareToPlay];
            [self.audioPlayer1 play];
            //STOP audioPlayer2 y 3 y 4
            [self.audioPlayer2 stop];
            [self.audioPlayer3 stop];
            [self.audioPlayer4 stop];

            NSLog(@"Estas lejos del item");

        }else if (SHORT_THRESHOLD<distance && distance<MEDIUM_THRESHOLD)
        {
            self.warningLabel1.text = @"CERCA";
            self.warningLabel2.text = @"CERCA";
            self.warningLabel1.backgroundColor = [UIColor yellowColor];
            self.warningLabel2.backgroundColor = [UIColor yellowColor];
            
            [self.audioPlayer2 prepareToPlay];
            [self.audioPlayer2 play];
            //STOP audioPlayer1 y 3 y 4
            [self.audioPlayer1 stop];
            [self.audioPlayer3 stop];
            [self.audioPlayer4 stop];
            
            NSLog(@"Estas cerca del item");
            
        }else if (ITEM_THRESHOLD < distance && distance < SHORT_THRESHOLD)
        {
            self.warningLabel1.text = @"MUY CERCA";
            self.warningLabel2.text = @"MUY CERCA";
            self.warningLabel1.backgroundColor = [UIColor cyanColor];
            self.warningLabel2.backgroundColor = [UIColor cyanColor];
                
            [self.audioPlayer3 prepareToPlay];
            [self.audioPlayer3 play];
            //STOP audioPlayer1 y 2 y 4
            [self.audioPlayer1 stop];
            [self.audioPlayer2 stop];
            [self.audioPlayer4 stop];
                
            NSLog(@"Estas muy cerca del item");
                
        }else if(distance < ITEM_THRESHOLD)
        {
            self.warningLabel1.text = @"ENCONTRADO";
            self.warningLabel2.text = @"ENCONTRADO";
            self.warningLabel1.backgroundColor = [UIColor greenColor];
            self.warningLabel2.backgroundColor = [UIColor greenColor];
            
            [self.audioPlayer4 prepareToPlay];
            [self.audioPlayer4 play];
            //STOP audioPlayer1, 2 y 3
            [self.audioPlayer1 stop];
            [self.audioPlayer2 stop];
            [self.audioPlayer3 stop];
            
            NSLog(@"!Enhorabuena, has encontrado el item¡");

        }else {
            
            self.warningLabel1.text = @"";
            self.warningLabel2.text = @"";
            self.warningLabel1.backgroundColor = [UIColor whiteColor];
            self.warningLabel2.backgroundColor = [UIColor whiteColor];
            
            // Sin aviso sonoro
            [self.audioPlayer1 stop];
            [self.audioPlayer2 stop];
            [self.audioPlayer3 stop];
            [self.audioPlayer4 stop];
            if (self.annotations.count != 0){
                NSLog(@"Estas muy lejos el item. Sigue buscando.");
            }else{
                NSLog(@"No hay items almacenados. Siga las instrucciones para almacenar uno.");
            }
        }
        if(distance < LARGE_THRESHOLD){
            self.distanceLabelMeters.text = [NSString stringWithFormat:@"%1.5f", distance];
        } else {
            if (self.annotations.count != 0){
                self.distanceLabelMeters.text = @"Demasiado lejos.";
            }else{
                self.distanceLabelMeters.text = @"---";
            }

        }
        
        // DIBUJADO DE LA TRAYECTORIA DEL USUARIO EN EL MAPA.
        if ((oldLocation.coordinate.latitude != newLocation.coordinate.latitude) &&
            (oldLocation.coordinate.longitude != newLocation.coordinate.longitude))
        {
            if (!self.crumbs)
            {
                _crumbs = [[CrumbPath alloc] initWithCenterCoordinate:newLocation.coordinate];
                [self.mapView addOverlay:self.crumbs];
                
                MKCoordinateRegion region =
                MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000);
                [self.mapView setRegion:region animated:YES];
            }
            else
            {
                MKMapRect updateRect = [self.crumbs addCoordinate:newLocation.coordinate];
                
                if (!MKMapRectIsNull(updateRect))
                {
                    MKZoomScale currentZoomScale = (CGFloat)(self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width);

                    CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
                    updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);

                    [self.crumbView setNeedsDisplayInMapRect:updateRect];
                }
            }
        }
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    if (!self.crumbView)
    {
        _crumbView = [[CrumbPathView alloc] initWithOverlay:overlay];
    }
    return self.crumbView;

}

// BORRA EL ANNOTATION SELECCIONADO EN EL MAPVIEW AL PULSAR EL BOTON BORRAR
- (IBAction)tappedRemove:(UIButton*)sender {
    
    for (MKPointAnnotation* annotation in self.mapView.annotations)
    {
        if (![annotation isKindOfClass:[MKUserLocation class]])
        {
            // ULTIMA ANNOTATION CLICKEADA (SELECTED)
            MKPointAnnotation *annotationSelected = [[self.mapView selectedAnnotations]objectAtIndex:0];
            
            if([annotation.title isEqual:annotationSelected.title])
            {
                // BORRAMOS INFORMACION LOCAL DEL ANNOTATION SELECIONADO:
                [self.annotations removeObject:annotation];
                [self.mapView removeAnnotation:annotation];
                
                // BORRAMOS INFORMACION REMOTA (parse.com) DEL ANNOTATION SELECCIONADO:
                
                // PARA ELLO DESCARGAMOS LOS ANNOTATIONS DE LA BBDD PARA LOCALIZAR EL ANNOTATION
                // SELECCIONADO (SE COMPARA EL NOMBRE DEL ANNOTATION, POR LO TANTO NO DEBEN HABER
                // 2 O MAS ITEMS CON EL MISMO NOMBRE. SE PUEDE COMPARAR TB LAS COORDENADAS (MEJORA).
                
                // CUALQUIER TERMINAL QUE EJECUTE LA APLICACION PODRA ELIMINAR CUALQUIER ITEM GUARDADO.
                // PARA EVITARLO, SE PUEDE REALIZAR SOPORTE DE USUARIOS CON LOGIN, ASI SOLO EL USUARIO
                // QUE HAYA CREADO UN ITEM, PODRA BORRARLO (MEJORA).
                
                // SI HAY SOPORTE DE USUARIOS, SE PUEDEN AÑADIR EXTRAS COMO QUE AL ENCONTRAR UN ITEM
                // EL ICONO DEL ITEM CAMBIE DE COLOR Y SE MANTENGA ASI PARA SIEMPRE (ITEM DESCUBIERTO).
                // CADA USUARIO TENDRA SUS ITEMS DESCUBIERTOS. (MEJORA).
                
                PFQuery *query = [PFQuery queryWithClassName:@"Location"];
                
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
                    if(!error)
                    {
                        NSString *nombreItem;
                        
                        for (int aux = 0; aux < objects.count; aux++)
                        {
                            // EN CADA OBJETO DE LA BBDD DE LA CLASE "Location", COMPARAMOS EL
                            // ELEMENTO "title" CON EL ANNOTATION SELECCIONADO EN EL MAPA
                            nombreItem = [objects[aux] objectForKey:@"title"];

                            if([annotation.title isEqual:nombreItem])
                            {
                                // SI COINCIDEN LOS NOMBRES, BORRAMOS DE LA BBDD EL ELEMENTO CON LA
                                // ID DEL ANNOTATION SELECCIONADO
                                NSString *objectIdItem = [objects[aux] objectId];
                                
                                PFObject *object = [PFObject objectWithoutDataWithClassName:@"Location" objectId:objectIdItem];
                                
                                [object deleteEventually];
                                
                                NSLog(@"--------------------------------------------------------------------------------");
                                NSLog(@"-----> Ha borrado el item con ID: %@ y nombre: %@", objectIdItem, nombreItem);
                                NSLog(@"--------------------------------------------------------------------------------");

                            }
                        }
                    }
                }];
            }
        }
    }
}

// ESCONDE EL TECLADO AL HACER TAP FUERA DE EL EN LA VISTA.
-(IBAction)hideKeyboardOnBackgroundTap:(UITapGestureRecognizer*)sender
{
    [self.itemNameTextField resignFirstResponder];
}

- (IBAction)unwindBack:(UIStoryboardSegue*)segue{
    // Back
}
@end
