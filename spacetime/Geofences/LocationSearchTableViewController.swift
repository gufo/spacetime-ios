//
// Copyright © 2018 Janko Luin. All rights reserved.
//

import UIKit
import MapKit
import Contacts
import CoreData

class LocationSearchTableViewController: UITableViewController {
    var managedObjectContext: NSManagedObjectContext!
    var searchController: UISearchController!
    var searchResults: [MKMapItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTouchCancelButton))

        self.searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.definesPresentationContext = false
        tableView.tableHeaderView = searchController.searchBar
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "location", for: indexPath)
        let mapItem = searchResults[indexPath.row]

        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title

        return cell
    }

    // MARK: - Table view events

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mapItem = searchResults[indexPath.row]

        let location = Location(context: managedObjectContext)
        location.title = mapItem.name
        location.address = mapItem.placemark.title
        location.latitude = mapItem.placemark.coordinate.latitude
        location.latitude = mapItem.placemark.coordinate.longitude
        location.radiusInMeters = 100
        location.createdAt = Date()

        do {
            try managedObjectContext.save()
            GeofencingController.current.add(location: location)
            performSegue(withIdentifier: "dismiss", sender: nil)
        } catch {
            fatalError(String(describing: error))
        }
    }

    // MARK: - UINavigationBar actions

    @objc func didTouchCancelButton() {
        self.dismiss(animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LocationSearchTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text else {
            self.searchResults = []
            return
        }

        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = query

        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            self.searchResults = response?.mapItems ?? []
            self.tableView.reloadData()
        }
    }
}
