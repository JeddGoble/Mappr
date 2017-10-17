//
//  ViewController.swift
//  ARFlickr
//
//  Created by jgoble52 on 10/10/17.
//  Copyright © 2017 Jedd Goble. All rights reserved.
//

import UIKit
import ARCL
import CoreLocation
import SceneKit
import SDWebImage
import ARKit

class ViewController: UIViewController {

    // Paste your own Flickr API Key here:
    var flickrAPIKey: String {
        return ""
    }
    
    var sceneLocationView = SceneLocationView()
    var locationNodes: Set<LocationAnnotationNode> = []
    
    var locationManager = CLLocationManager()
    
    var downloadTimer: Timer?
    var downloadAllowed: Bool = true
    
    var dateTakenPage: Int = 1
    var relevancePage: Int = 1
    var interestingnessPage: Int = 1
    
    var isPresentingFilterMethodView: Bool = false
    var filterMethod: FilterMethod = .dateTaken
    
    var firstLayout: Bool = true
    
    @IBOutlet weak var arViewContainer: UIView!
    
    @IBOutlet weak var methodSelectViewContainer: UIView!
    
    @IBOutlet weak var reloadButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneLocationView.locationDelegate = self
        sceneLocationView.run()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneLocationView.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard firstLayout else {
            return
        }
        
        firstLayout = false
        sceneLocationView.frame = arViewContainer.bounds
        arViewContainer.addSubview(sceneLocationView)
        sceneLocationView.bindFrameToSuperviewBounds()
        addMethodSelectView()
    }
    
    func addMethodSelectView() {
        guard let bundleView = Bundle.main.loadNibNamed(MethodSelectView.nibName, owner: nil, options: nil)?.first as? MethodSelectView else {
            return
        }
        
        bundleView.delegate = self
        methodSelectViewContainer.addSubview(bundleView)
        bundleView.frame = methodSelectViewContainer.bounds
        
        methodSelectViewContainer.isHidden = !isPresentingFilterMethodView
    }
    
    @objc func reEnableDownloadAllowed() {
        
        loadMoreImages(removeAllNodes: false, iteratePage: true)
    }
    
    func downloadPhotos(photos: [FlickrPhoto], userLocation: CLLocation) {
        
        print("Attempting photos download")
        
        for photo in photos {
            guard let urlString = photo.urlString, let url = URL(string: urlString) else {
                print("Photo has no URL")
                continue
            }
            
            guard let lat = photo.latitude, let lon = photo.longitude else {
                continue
            }
            
            let photoLocation = CLLocation(latitude: lat, longitude: lon)
            let distance = userLocation.distance(from: photoLocation)
            
            if distance < 100.0 {
                SDWebImageDownloader().downloadImage(with: url, options: .highPriority, progress: nil, completed: { (image, data, error, completed) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    
                    guard let image = image else {
                        print("Image download unsuccessful")
                        return
                    }
                    
                    self.addAnnotation(photo: photo, image: image)
                })
            }
        }
    }
    
    func addAnnotation(photo: FlickrPhoto, image: UIImage) {
        guard let lat = photo.latitude, let lon = photo.longitude else {
            return
        }
        
        let location = CLLocation(latitude: lat, longitude: lon)
        
        // Check for identical coordinates and discard if found ... prevents flickering images
        for node in locationNodes {
            if node.location.coordinate.latitude == location.coordinate.latitude && node.location.coordinate.longitude == location.coordinate.longitude {
                return
            }
        }
        
        let annotationNode = LocationAnnotationNode(location: location, image: image)
        annotationNode.scaleRelativeToDistance = true
        locationNodes.insert(annotationNode)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        print("Added annotation")
    }
    
    @IBAction func onFilterMethodButtonTapped(_ sender: UIButton) {
        
        isPresentingFilterMethodView = !isPresentingFilterMethodView
        methodSelectViewContainer.isHidden = !isPresentingFilterMethodView
        view.bringSubview(toFront: methodSelectViewContainer)
    }
    
    @IBAction func onReloadButtonTapped(_ sender: UIButton) {
        loadMoreImages(removeAllNodes: true, iteratePage: true)
    }
    
    func loadMoreImages(removeAllNodes: Bool, iteratePage: Bool) {
        
        reloadButton.isEnabled = false
        
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { (timer) in
            self.reloadButton.isEnabled = true
        }
        
        if removeAllNodes {
            for node in locationNodes {
                sceneLocationView.removeLocationNode(locationNode: node)
            }
        }
        
        if iteratePage {
            switch filterMethod {
            case .dateTaken:
                dateTakenPage += 1
            case .relevance:
                relevancePage += 1
            case .interestingness:
                interestingnessPage += 1
            }
        }
        
        downloadAllowed = true
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard downloadAllowed == true else {
            return
        }
        
        downloadAllowed = false
        downloadTimer = Timer.scheduledTimer(timeInterval: 120.0, target: self, selector: #selector(self.reEnableDownloadAllowed), userInfo: nil, repeats: false)
        
        guard let location = locations.first else {
            print("No location found")
            return
        }
        
        guard flickrAPIKey.characters.count > 0 else {
            print("No Flickr API key found. Paste your key into the String at the top of ViewController.swift")
            return
        }
        
        print("Attempting Flickr API call")
        
        var page: Int = 1
        
        switch filterMethod {
        case .dateTaken:
            page = dateTakenPage
        case .relevance:
            page = relevancePage
        case .interestingness:
            page = interestingnessPage
        }
        
        let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(flickrAPIKey)&format=json&accuracy=16&sort=date-posted-desc&per_page=250&page=\(page)&nojsoncallback=1&sort=\(filterMethod.apiArgument)&extras=url_m,geo&radius=1&lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)"
        print(urlString)
        
        if let url = URL(string: urlString) {
            let urlSession = URLSession.shared
            let task = urlSession.dataTask(with: url, completionHandler: { (data, response, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
                
                guard let data = data else {
                    print("Data returned null")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any] {
                        
                        if let root = json["photos"] as? [String : Any], let photosJson = root["photo"] as? [[String : Any]] {
                            var photos: [FlickrPhoto] = []
                            
                            for photoJson in photosJson {
                                if let photo = FlickrPhoto(json: photoJson) {
                                    photos.append(photo)
                                }
                            }
                            
                            DispatchQueue.main.async {
                                self.downloadPhotos(photos: photos, userLocation: location)
                            }
                        }
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            })
            
            task.resume()
        }
    }
    
}

extension ViewController: MethodSelectDelegate {
    
    func tappedMethodButton(method: FilterMethod) {
        
        filterMethod = method
        
        loadMoreImages(removeAllNodes: true, iteratePage: false)
        
        methodSelectViewContainer.isHidden = true
        isPresentingFilterMethodView = false
    }
}

extension ViewController: SceneLocationViewDelegate {
    
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        
    }
    
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        
    }
    
    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
        
    }
    
    func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
        
    }
    
    func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {
        
    }
}

