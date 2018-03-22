//
// Copyright © 2018 Janko Luin. All rights reserved.
//

import Foundation
import CoreLocation

extension Location {
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}
