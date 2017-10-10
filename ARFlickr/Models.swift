//
//  Models.swift
//  ARFlickr
//
//  Created by jgoble52 on 10/10/17.
//  Copyright © 2017 Jedd Goble. All rights reserved.
//

import Foundation
import UIKit

struct FlickrResponse: Codable {
    
    init?(json: [String:Any]) {
        guard let root = json["photos"] as? [String:Any], let photos = root["photo"] as? [FlickrPhotoData] else {
            return
        }
        
        self.photos = photos
    }
    
    var photos: [FlickrPhotoData]?
}

struct FlickrPhotoData: Codable {
    
    init?(json: [String:Any]) {
        if let title = json["title"] as? String {
            self.title = title
        }
        if let id = json["id"] as? String {
            self.id = id
        }
        if let owner = json["owner"] as? String {
            self.owner = owner
        }
    }
    
    var title: String?
    var id: String?
    var owner: String?
}

struct FlickrPhoto {
    
    var photoData: FlickrPhotoData
    var image: UIImage?
}
