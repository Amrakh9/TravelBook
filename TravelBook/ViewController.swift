//
//  ViewController.swift
//  TravelBook
//
//  Created by Amrah on 13.06.24.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    //Ümumiyyətlə userin current locationunu almaq üçün MapKit-dən istf. edilmir. Bunun üçün biz Core Location Manager-dən istifadə edirik.
    var locationManager = CLLocationManager()
    var chosenLongtidude = Double()
    var chosenLatitude = Double()
    
    var chosenTitle = ""
    var chosenID = UUID()
    
    var annotationTitle = ""
    var annotationDesc = ""
    var annotationLongitude = Double()
    var annotationLatitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //Ne qeder deqiqlikde alirsan locationu
        locationManager.requestWhenInUseAuthorization() //Ne zaman isteyirsen
        locationManager.startUpdatingLocation() // Userin locationunu bunnan almaga baslayiriq
        
        
        //RECOGNIZERS
        let gestureRecognizerforKeyboard = UITapGestureRecognizer(target: self, action: #selector(hideKeyboardFunc))
        view.addGestureRecognizer(gestureRecognizerforKeyboard)
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if chosenTitle != ""{
            //Core Data
            saveButton.isEnabled = false
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = chosenID.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject]{
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationDesc = subtitle
                                if let latitude = result.value(forKey: "latidude") as? Double {
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longtitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationDesc
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameTextField.text = annotationTitle
                                        descriptionTextField.text = annotationDesc
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("Error")
            }
        } else {
            saveButton.isEnabled = false
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameTextField.text, forKey: "title")
        newPlace.setValue(descriptionTextField.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latidude")
        newPlace.setValue(chosenLongtidude, forKey: "longtitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("Success")
        } catch {
            print("Error")
        }
        
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        //Link BACK action
        navigationController?.popViewController(animated: true)
    }
    @objc func hideKeyboardFunc(){
        view.endEditing(true)
    }
    
    @objc func longPress(gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            
            chosenLatitude = touchedCoordinates.latitude
            chosenLongtidude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameTextField.text
            annotation.subtitle = descriptionTextField.text
            self.mapView.addAnnotation(annotation)
            saveButton.isEnabled = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if chosenTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) //Current Location
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) //Xeritede ne qeder yaindan gorunsun
            let region = MKCoordinateRegion(center: location, span: span) //Merkezi hara olsun ve ne qeder zoom edim
            mapView.setRegion(region, animated: true)
        }
        else {
            print("Error on map component")
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.red
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if chosenTitle != "" {
            saveButton.isEnabled = false
            let requestLocaion = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocaion) { (placemarks, error) in
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }
    
    
}
