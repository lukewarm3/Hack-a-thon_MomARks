//
//  MapManager.swift
//  ARMap
//
//  Created by Luke Cao on 3/22/25.
//

import Foundation
import CoreLocation

struct Place: Hashable, Codable, Identifiable {
  var id: String
  var name: String
  var age: String
  var description: String?
    
    var latitude: Double?
    var longitude: Double?
    
    // TODO: later change the lat and long to not optional
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude ?? 41.69878133392592, longitude: longitude ?? -86.23516434558917)
    }
}



class MapManager {
    
}
