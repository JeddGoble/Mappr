//
//  Models.swift
//  ARFlickr
//
//  Created by jgoble52 on 10/10/17.
//  Copyright © 2017 Jedd Goble. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

struct FlickrPhoto: Codable {
    
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
        if let urlString = json["url_m"] as? String {
            self.urlString = urlString
        }
        if let latString = json["latitude"] as? String, let latDouble = Double(latString), let lonString = json["longitude"] as? String, let lonDouble = Double(lonString) {
            self.latitude = latDouble
            self.longitude = lonDouble
        }
    }
    
    var title: String?
    var id: String?
    var owner: String?
    var urlString: String?
    var latitude: Double?
    var longitude: Double?
}

enum FilterMethod {
    case dateTaken
    case relevance
    case interestingness
    
    var apiArgument: String {
        switch self {
        case .dateTaken:
            return "date-posted-desc"
        case .relevance:
            return "relevance"
        case .interestingness:
            return "interestingness-desc"
        }
    }
}
