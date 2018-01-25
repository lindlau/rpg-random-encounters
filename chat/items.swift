//
//  items.swift
//  chat
//
//  Created by Bartosz Bibersztajn on 18/01/2018.
//  Copyright © 2018 Scairp. All rights reserved.
//

import UIKit
import CoreData

class items: UIViewController,UITableViewDelegate,UITableViewDataSource,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    //opener data
    var passedSection:SectionsCD?
    var sectionId:NSManagedObjectID?
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let imagePicker = UIImagePickerController()
    
    var itemsData:[ItemsCD] = []
    var itemId:Int?
    
    @IBOutlet weak var emptyList: UIView!
    
    @IBOutlet weak var itemTable: UITableView!
    @IBOutlet weak var editContainer: UIView!
    @IBOutlet weak var editContainerBackground: UIView!
    
    @IBAction func capture(sender: AnyObject) { // button action
        let Picker = UIImagePickerController()
        Picker.delegate = self
        Picker.sourceType = .photoLibrary
        self.present(Picker, animated: true, completion: nil)
        Picker.allowsEditing = true
        Picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            newAvatar.image = resizeImage(image: pickedImage, targetSize: CGSize(width:600, height:600)) 
        }
        dismiss(animated: true, completion: nil)
        nameInput.becomeFirstResponder()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion:nil)
        nameInput.becomeFirstResponder()
    }
    
    @IBOutlet weak var nameInput: UITextField!
    @IBOutlet weak var infoInput: UITextView!
    
    @IBOutlet weak var newAvatar: UIImageView!
    @IBOutlet weak var probabilityValue: UISlider!
    @IBAction func probabilityAction(_ sender: UISlider) {
        //print(sender.value)
    }
    
    
    @IBOutlet weak var rightNavButton: UIBarButtonItem!
    @IBAction func addNewRow(_ sender: UIBarButtonItem) {
        addRowAction()
    }
    
    @objc func addRowAction() {
        resetEditing()
        if editContainerBackground.isHidden == false {
            nameInput.becomeFirstResponder()
        } else {
            self.view.endEditing(true)
        }
    }
    
    func resetEditing() {
        if itemId != nil {
            itemTable.deselectRow(at: [0,itemId!], animated: true)
        }
        itemId = nil
        nameInput.text = ""
        infoInput.text = ""
        probabilityValue.value = 0.5
        newAvatar.image = #imageLiteral(resourceName: "black")
        self.view.endEditing(true)
        toggleEdit( view: editContainer, background: editContainerBackground)
    }
    
    @IBAction func addDataButton(_ sender: Any) {
        if let itemId:Int = itemId {
            updateData(name: nameInput.text!, info: infoInput.text!, id: itemId )
        } else {
            addData(name: nameInput.text!, info: infoInput.text!)
        }
        resetEditing()
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        resetEditing()
    }
    
    func updateData( name:String = "Title", info:String = "Description", id:Int) {

        itemsData = passedSection?.toItems?.allObjects as! [ItemsCD]
        itemsData[id].name = name
        itemsData[id].info = info
        itemsData[id].image = UIImageJPEGRepresentation(newAvatar.image!, 0.65)
        itemsData[id].probability = probabilityValue.value

        // Save the data to coredata
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        getData()
    }
    
    func addData( name:String = "Title", info:String = "Description") {
        let item = ItemsCD(context: context) // Link Task & Context
        item.name = name
        item.info = info
        item.image = UIImageJPEGRepresentation(newAvatar.image!, 0.65)
        item.probability = probabilityValue.value
        item.toSections = passedSection
        passedSection?.toItems?.adding(item)
        // Save the data to coredata
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        getData()
    }
    
    func getData() {
        itemsData = passedSection?.toItems?.allObjects as! [ItemsCD]
        if itemsData.count > 0 {
            emptyList.isHidden = true
            itemTable.reloadData()
        } else {
            emptyList.isHidden = false
        }
    }
 
    /*
    func getData2() {
        do {
            itemsData = try context.fetch(ItemsCD.fetchRequest())
            itemTable.reloadData()
            if itemsData.count > 0 {
                //itemTable.scrollToRow(at: [0,items.count - 1] , at: .bottom, animated: true)
            }
        } catch {
            print("Fetching Failed")
        }
    }
 */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemTable.delegate = self
        itemTable.dataSource = self
        infoInput.layer.cornerRadius = 6
        newAvatar.layer.cornerRadius = 6
        infoInput.layer.borderColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
        infoInput.layer.borderWidth = 1
        // Do any additional setup after loading the view.
        self.title = passedSection?.name
        getData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(sections.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sections.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    @objc func keyboardWillShow(_ notification:Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            editContainerBackground.transform = CGAffineTransform(translationX:0, y:keyboardSize.height * (-1) )
        }
    }
    @objc func keyboardWillHide(_ notification:Notification) {
        if let _ = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            editContainerBackground.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! itemCell
        let data = itemsData[indexPath.row]
        cell.avatar.image = #imageLiteral(resourceName: "black")
        cell.name.text = data.name
        cell.smallLabel.text = data.info
            //?? "") TS:\(data.toSections)"
        cell.probabilityLabel.text = String( format:"%.2f", data.probability )
        if data.probability < 0.11 {
           cell.probabilityLabel.textColor = #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)
        } else if data.probability < 0.21 {
            cell.probabilityLabel.textColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
        } else if data.probability < 0.81 {
            cell.probabilityLabel.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        } else {
            cell.probabilityLabel.textColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
        }
        if data.image != nil {
            cell.avatar.image = UIImage(data: data.image!)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        nameInput.text = itemsData[indexPath.row].name
        infoInput.text = itemsData[indexPath.row].info
        probabilityValue.value = itemsData[indexPath.row].probability
        if itemsData[indexPath.row].image != nil {
            newAvatar.image = UIImage(data: itemsData[indexPath.row].image!)
        }
        itemId = indexPath.row
        toggleEdit( view: editContainer, background: editContainerBackground ,state: true)
        nameInput.becomeFirstResponder()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = itemsData[indexPath.row]
            context.delete(item)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            itemsData = passedSection?.toItems?.allObjects as! [ItemsCD]
        }
        itemTable.deleteRows(at: [indexPath], with: .automatic)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.view.endEditing(true)
    }

}

class itemCell: UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var smallLabel: UILabel!
    @IBOutlet weak var probabilityLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatar.layer.cornerRadius = 6
    }
}

extension UIViewController {
    func toggleEdit(view:UIView,background:UIView,state:Bool = false) {
        UIView.animate(withDuration: 0.3, animations: {
            if view.isHidden == true || state == true {
                //constrain.constant = 0
                view.isHidden = false
                background.isHidden = false
            } else {
                //constrain.constant = 150
                view.isHidden = true
                background.isHidden = true
            }
            self.view.layoutIfNeeded()
            self.view.endEditing(true)
        })
    }
}
