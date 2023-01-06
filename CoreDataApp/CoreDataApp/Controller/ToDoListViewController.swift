//
//  ToDoListViewController.swift
//  CoreDataApp
//
//  Created by dzmitry on 6.01.23.
//

import UIKit
import CoreData

class ToDoListViewController: UITableViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var selectedCategory: CategoryModel? {
        didSet {
            self.title = selectedCategory?.name
            loadItems()
        }
    }

    var itemsArray = [ItemModel]()

    @IBAction func addNewItemActoion(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add new item", message: "", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Your new task"
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            if let texField = alert.textFields?.first,
               let text = texField.text,
               text != "",
               let self = self {
                let newItem = ItemModel(context: self.context)
                newItem.title = text
                newItem.done = false
                newItem.parentCategory = self.selectedCategory
                
                self.itemsArray.append(newItem)
                self.saveItems()
                self.tableView.insertRows(at: [IndexPath(row: self.itemsArray.count - 1, section: 0)], with: .automatic)
            }
        }
        
        alert.addAction(cancel)
        alert.addAction(addAction)
        
        self.present(alert, animated: true)
    }
    
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        itemsArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let item = itemsArray[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done ? .checkmark : .none // checkmark (галочка)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let categoryName = selectedCategory?.name,
               let itemName = itemsArray[indexPath.row].title {
                let request: NSFetchRequest<ItemModel> = ItemModel.fetchRequest()
                        
                // Вариант с 2-мя придикатами
                let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", categoryName)
                let itemPredicate = NSPredicate(format: "title MATCHES %@", itemName)
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates:
                                                            [categoryPredicate, itemPredicate])
                        
                // Вариант с 1-м придикатом (в данном случае неправильное решение)
                // подходит если использовать UUID
                // request.predicate = NSPredicate(format: "title MATCHES %@", itemName)
                if let results = try? context.fetch(request) {
                    for object in results {
                        context.delete(object)
                    }
                    // Save the context and delete the data locally
                    itemsArray.remove(at: indexPath.row) // удалили из массива
                    saveItems() // сохранили в базу данных
                    tableView.deleteRows(at: [indexPath], with: .automatic) // удалили ячейку из таблицы
                }
            }
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // при нажатии на ячейку, убираем выделение серым цветом
        itemsArray[indexPath.row].done.toggle() // добавляем отображение галочки
        self.saveItems() // запускаем отображение галочки по нажатию на ячейку
        tableView.reloadRows(at: [indexPath], with: .fade) // перезагрузить 1 ячейку в таблице
    }
    
    // MARK: - Core Data
    
    private func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error save context")
        }
    }
        
    private func loadItems(with request: NSFetchRequest<ItemModel> = ItemModel.fetchRequest(),
                           predicate: NSPredicate? = nil)
    {
        guard let name = selectedCategory?.name else {
            return
        }
        // второй вариант создания предиката "parentCategory.name MATCHES %@", name
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", name)
            
        if let predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, categoryPredicate])
        } else {
            request.predicate = categoryPredicate
        }
        
        do {
            itemsArray = try context.fetch(request)
        } catch {
            print("Error fetch context")
        }
        tableView.reloadData()
    }
}

// MARK: - Search

extension ToDoListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText.isEmpty {
            loadItems()
            searchBar.resignFirstResponder() // завершение ввода (скрытие клавиатуры)
        } else {
            let request: NSFetchRequest<ItemModel> = ItemModel.fetchRequest()
            let searchPredicate = NSPredicate(format: "title CONTAINS %@", searchText)
            request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)] // сортировка
            loadItems(with: request, predicate: searchPredicate)
        }
    }
}
