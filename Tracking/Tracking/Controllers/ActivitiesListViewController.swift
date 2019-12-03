//
//  ActivitiesListViewController.swift
//  Tracking
//
//  Created by Jose Manuel on 02/12/19.
//  Copyright © 2019 Jose Manuel. All rights reserved.
//

import Foundation
import UIKit
import Foundation
import CoreData

class ActivitiesListViewController: UITableViewController {

    private var track: Tracking?
    var list: [NSManagedObject] = []
    private var distance = Measurement(value: 0, unit: UnitLength.meters)
    var fetchedResultsController: NSFetchedResultsController<Tracking> = NSFetchedResultsController()
    var coreDataStack: CoreDataStack!
    
    override func viewWillAppear(_ animated: Bool) {
         list = getRuns()
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
      super.viewDidLoad()
        
        list = getRuns()
        self.tableView.reloadData()
    }
     func updateView() {
         list = getRuns()
               self.tableView.reloadData()
    }
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    private func getRuns() -> [Tracking] {
      let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: #keyPath(Tracking.timestamp), ascending: true)
      fetchRequest.sortDescriptors = [sortDescriptor]
      do {
        return try CoreDataStack.context.fetch(fetchRequest)
      } catch {
        return []
      }
    }
}

extension ActivitiesListViewController {
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return list.count
  }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           guard let cell = tableView.dequeueReusableCell(withIdentifier: TrackCell.reuseIdentifier, for: indexPath) as? TrackCell else {
               fatalError("Unexpected Index Path")
           }
           // Configure Cell
           configure(cell, at: indexPath)
           return cell
       }

    func configure(_ cell: TrackCell, at indexPath: IndexPath) {
        
        let person = list[indexPath.row]
        if let name = person.value(forKey: "name") {
            cell.textName.text = name as? String
        }
        if let result = ((person.value(forKey: "distance")) as AnyObject).doubleValue {
            let formattedDistance = FormatDisplay.distance(result)
            cell.textDistance.text = formattedDistance
        }
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard case(.delete) = editingStyle else { return }
        
        let moc = getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tracking")
        
        let result = try? moc.fetch(fetchRequest)
        let resultData = result as! [Tracking]
        
        if resultData.count > 0 {
            moc.delete(resultData[0])
        }
        do {
            try moc.save()
            list = getRuns()
            self.tableView.reloadData()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension ActivitiesListViewController: NSFetchedResultsControllerDelegate {

   func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.tableView.beginUpdates()
     }

     func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()

         updateView()
     }
}
extension ActivitiesListViewController: SegueHandlerType {
  enum SegueIdentifier: String {
    case details = "TrackDetailsViewController"
  }
  
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .details:
            guard let  destination = segue.destination as? TrackDetailsViewController else { return }
            let indexPath = tableView.indexPathForSelectedRow!
            destination.track = list[indexPath.row] as? Tracking
        }
    }
}
