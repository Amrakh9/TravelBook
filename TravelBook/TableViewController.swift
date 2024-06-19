//
//  TableViewController.swift
//  TravelBook
//
//  Created by Amrah on 15.06.24.
//

import UIKit
import CoreData

class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var titleArray = [String]()
    var idArray = [UUID]()
    
    var selectedTitle = ""
    var selectedTitleID: UUID?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButton))
        
        tableView.delegate = self
        tableView.dataSource = self
        
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    @objc func getData(){
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let context = appDelegate?.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context?.fetch(request)
        
            self.titleArray.removeAll(keepingCapacity: false)
            self.idArray.removeAll(keepingCapacity: false)
            
            if results!.count > 0 {
                for result in results as! [NSManagedObject]{
                    if let title = result.value(forKey: "title") as? String {
                        self.titleArray.append(title)
                    }
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                    }
                    tableView.reloadData()
                }
            }
            print("Success")
        } catch{
            print("Error")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTitle = titleArray[indexPath.row]
        selectedTitleID = idArray[indexPath.row]
        
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    //Deleting specific row
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let context = appDelegate?.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = idArray[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context?.fetch(fetchRequest)
                if let results = results as? [NSManagedObject], results.count > 0 {
                    for result in results {
                        if let id = result.value(forKey: "id") as? UUID, id == idArray[indexPath.row] {
                            context!.delete(result)
                            titleArray.remove(at: indexPath.row)
                            idArray.remove(at: indexPath.row)
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                            
                            do {
                                try context!.save()
                            } catch {
                                print("Error saving context after deletion")
                            }
                            break
                        }
                    }
                }
            } catch {
                print("Error fetching data for deletion")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewController" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.chosenTitle = selectedTitle
            if let selectedID = selectedTitleID {
                destinationVC.chosenID = selectedID
            } else {
                // Handle the case where selectedTitleID is nil
            }
        }
    }
    
    @objc func addButton(){
        selectedTitle = ""
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
}
