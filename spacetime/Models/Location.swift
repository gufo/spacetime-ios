//
// Copyright © 2018 Janko Luin. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

extension Location {
    static func named(_ name: String) -> NSFetchRequest<Location> {
        let request: NSFetchRequest<Location> = self.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(title), name)
        return request
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }

    func startVisit(date: Date) {
        let visit = Visit.init(entity: Visit.entity(), insertInto: managedObjectContext)
        visit.location = self
        visit.started = date
        visit.ended = nil
    }

    func currentVisit() -> Visit? {
        guard let visit = visits?.lastObject as? Visit else {
            return nil
        }

        if visit.ended == nil {
            return visit
        } else {
            return nil
        }
    }
}
