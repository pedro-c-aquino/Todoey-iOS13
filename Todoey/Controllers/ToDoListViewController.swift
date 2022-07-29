//
//  ViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class ToDoListViewController: SwipeTableViewController {
    
    var todoItems: Results<Item>?
    let realm  = try! Realm()
    
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let colorHex = selectedCategory?.color {
            
            /*
                       First we set the title to match the category. We know that it exist since we are inside our if let statement here:
                       */
                      title = selectedCategory!.name
           
                      /*
                       Set the colour to use here:
                       */
                      let theColourWeAreUsing = UIColor(hexString: colorHex)!
           
                      /*
                       Then let us set the background colour of the search bar as well:
                       */
//                      searchBar.barTintColor = theColourWeAreUsing
           
                      /*
                       THen we will set the colours. Using navigationController?.navigationBar.backgroundColor is not an option here because in iOS 13, the status bar at the very top does not change colour (strangely enough). After Googling this, I found a solution where they use UINavigationBarAppearance() instead.
                       */
                      let navBarAppearance = UINavigationBarAppearance()
                      let navBar = navigationController?.navigationBar
                      let navItem = navigationController?.navigationItem
                      navBarAppearance.configureWithOpaqueBackground()
           
                      /*
                       We use Chameleon's ContrastColorOf() function to set the colour of the text based on the colour we use. If it is dark, the text is light, and vice versa.
                       */
                      let contrastColour = ContrastColorOf(theColourWeAreUsing, returnFlat: true)
           
                      navBarAppearance.titleTextAttributes = [.foregroundColor: contrastColour]
                      navBarAppearance.largeTitleTextAttributes = [.foregroundColor: contrastColour]
                      navBarAppearance.backgroundColor = theColourWeAreUsing
                      navItem?.rightBarButtonItem?.tintColor = contrastColour
                      navBar?.tintColor = contrastColour
                      navBar?.standardAppearance = navBarAppearance
                      navBar?.scrollEdgeAppearance = navBarAppearance
           
                      self.navigationController?.navigationBar.setNeedsLayout()
        }

    }
    
    //MARK - Tableview Datasource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if let item = todoItems?[indexPath.row] {
            cell.textLabel?.text = item.title
            
            if let color = UIColor(hexString: selectedCategory!.color)?.darken(byPercentage: CGFloat(indexPath.row)/CGFloat(todoItems!.count))
            {
                cell.backgroundColor = color
                cell.textLabel?.textColor = ContrastColorOf(color, returnFlat: true)
            }
                                                
            cell.accessoryType = item.done ? .checkmark : .none
        } else {
            cell.textLabel?.text = "No Items Added"
        }
        
        return cell
    }
    
    //MARK - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let item = todoItems?[indexPath.row] {
            do {
                try realm.write({
                    item.done = !item.done
                })
            } catch  {
                print("Error saving done status, \(error)")
            }
        }
        
        tableView.reloadData()
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    //MARK - Add New Items
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Todoey Item", message: "", preferredStyle: .alert)
        
        let action  = UIAlertAction(title: "Add Item", style: .default) { action in
            //what will happen once the user clicks the Add Item button on our UIAlert
            
            if let currentCategory = self.selectedCategory {
                do {
                    try self.realm.write {
                        let newItem = Item()
                        newItem.title = textField.text!
                        newItem.dateCreated = Date()
                        currentCategory.items.append(newItem)
                    }
                } catch {
                    print("Error saving item \(error)")
                }
            }
            
            self.tableView.reloadData()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    func loadItems() {
        
        todoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: false)
        tableView.reloadData()
        
    }
    
    override func updateModel(at indexPath: IndexPath) {
        if let item = todoItems?[indexPath.row] {
            do {
                try realm.write {
                    realm.delete(item)
                }
            } catch  {
                print("Error deleting item: \(error)")
            }
        }
    }
}

//MARK: - Search bar methods

extension ToDoListViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)
        
        tableView.reloadData()

    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()

            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }

        }

    }
}

