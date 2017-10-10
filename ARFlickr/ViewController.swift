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

class ViewController: UIViewController {

    var sceneLocationView = SceneLocationView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneLocationView.run()
        view.addSubview(sceneLocationView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneLocationView.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sceneLocationView.frame = view.bounds
    }
    
    func downloadPhotos(flickrResponse: FlickrResponse) {
        guard let photosData = flickrResponse.photos else {
            print("No photos in response")
            return
        }
        
        for photoData in photosData {
            
        }
    }
    
}

extension ViewController: SceneLocationViewDelegate {
    
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        
        let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=0fa112504f3a3e7c9d74cad429d6f709&format=json&accuracy=16&sort=date-posted-desc&per_page=10&lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)"
        if let url = URL(string: urlString) {
            let urlSession = URLSession(configuration: .default)
            urlSession.dataTask(with: url, completionHandler: { (data, response, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
                
                guard let data = data else {
                    print("Data returned null")
                    return
                }
                
                do {
                    let flickrResponse = try JSONDecoder().decode(FlickrResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.downloadPhotos(flickrResponse: flickrResponse)
                    }
                } catch let jsonError {
                    print(jsonError.localizedDescription)
                }
            }).resume()
        }
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

