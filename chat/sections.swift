//
//  ViewController.swift
//  chat
//
//  Created by Bartosz Bibersztajn on 18/01/2018.
//  Copyright © 2018 Scairp. All rights reserved.
//

import UIKit
import CoreData

class sections: UIViewController,UITableViewDataSource,UITableViewDelegate,sectionDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIDocumentPickerDelegate {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var sectionsData: [SectionsCD] = []
    var sectionId:Int?
    let imagePicker = UIImagePickerController()

    @IBOutlet weak var emptyList: UIView!
    
    @IBOutlet weak var sectionTable: UITableView!
    
    @IBOutlet weak var editHolder: UIView!
    @IBOutlet weak var editTextField: UITextField!
    @IBOutlet weak var editCreditField: UITextField!
    
    @IBAction func cancelEditing(_ sender: Any) {
        stopEditing()
    }
    @IBAction func saveEditing(_ sender: Any) {
        saveEditing()
    }
    
    @IBAction func enterPressed(_ sender: Any) {
        saveEditing()
    }
    
    @IBAction func importGroupAction(_ sender: Any) {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: ["public.text"], in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker, animated: true, completion: nil)
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if controller.documentPickerMode == UIDocumentPickerMode.import {
            // This is what it should be
            doExportImport.importData(file: url,completion: { success in
                if success {
                    self.alert(title:"Done" ,message:"New Encounters added")
                    getData()
                } else {
                    self.alert(title:"Error" ,message:"Something went wrong, probably corrupted file.")
                }
            })
        }
    }
    
    func startEditing() {
        editTextField.becomeFirstResponder()
        editTextField.text = currentElement?.name
        editCreditField.text = currentElement?.credit
        editHolder.isHidden = false
    }
    
    //currentIndex = index
    //currentElement = data
    
    func saveEditing() {
        currentElement?.name = editTextField.text
        currentElement?.credit = editCreditField.text
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        sectionTable.reloadData()
        stopEditing()
    }
    
    func stopEditing() {
        editHolder.isHidden = true
        self.view.endEditing(true)
    }
    
    @IBAction func addSection(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "SectionsCD", in: context)
        let newSection = NSManagedObject(entity: entity!, insertInto: context)
        newSection.setValue("", forKey: "info")
        newSection.setValue("", forKey: "name")
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
        getData()
        sectionTable.scrollToRow(at: [0,sectionsData.count - 1] , at: .bottom, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.title = "Sections"
        getData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.title = " "
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sectionTable.delegate = self
        sectionTable.dataSource = self

        NotificationCenter.default.addObserver(self, selector: #selector(sections.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sections.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    @objc func keyboardWillShow(_ notification:Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            editHolder.transform = CGAffineTransform(translationX:0, y:keyboardSize.height * (-1) )
        }
    }
    @objc func keyboardWillHide(_ notification:Notification) {
        if let _ = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            editHolder.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    
    func getData() {
        do {
            sectionsData = try context.fetch(SectionsCD.fetchRequest())
            sectionTable.reloadData()
            if sectionsData.count > 0 {
                //itemTable.scrollToRow(at: [0,items.count - 1] , at: .bottom, animated: true)
                emptyList.isHidden = true
            } else {
                emptyList.isHidden = false
            }
        } catch {
            print("Fetching Failed")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionsData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sectionCell", for: indexPath) as! sectionCell
        let data = sectionsData[indexPath.row]
        let itemsCount:Int = data.toItems!.allObjects.count
        cell.name.text = data.name
        cell.credit.text = data.credit
        cell.avatar.image = #imageLiteral(resourceName: "black")
        if data.image != nil {
            cell.avatar.image = UIImage(data: data.image!)
        }
        if data.isVisible == "1" {
            cell.isVisibleLabel.isOn = true
        } else {
            cell.isVisibleLabel.isOn = false
        }
        
        if itemsCount > 0 {
            cell.encountersLabel.text = "\(itemsCount) Encouters"
        } else {
            cell.encountersLabel.text = ""
        }
        cell.data = data
        cell.index = indexPath.row
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = sectionsData[indexPath.row]
            context.delete(item)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            do {
                sectionsData = try context.fetch(SectionsCD.fetchRequest())
            } catch {
                print("Fetching Failed")
            }
        }
        //resetEditing()
        sectionTable.deleteRows(at: [indexPath], with: .automatic)
    }

    func editSection(_ index: Int,data:SectionsCD) {
        currentIndex = index
        currentElement = data
        startEditing()
    }
    
    var currentIndex:Int = 0
    var currentElement:SectionsCD?
    func updateImage(_ index:Int, data:SectionsCD) {
        let Picker = UIImagePickerController()
        Picker.delegate = self
        Picker.sourceType = .photoLibrary
        self.present(Picker, animated: true, completion: nil)
        Picker.allowsEditing = true
        Picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        currentIndex = index
        currentElement = data
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            let cell = sectionTable.cellForRow(at: [0,currentIndex] ) as! sectionCell
            //update image in table
            let saveImage = resizeImage(image: pickedImage, targetSize: CGSize(width:600, height:600))
            cell.avatar.image = saveImage
            //update image in core data
            currentElement?.image = UIImageJPEGRepresentation(cell.avatar.image!, 0.65) 
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            getData()
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion:nil)
    }
    
    func addEncounterToSection(_ index: Int,data:SectionsCD) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "items") as? items {
            //viewController.newsObj = newsObj
            vc.passedSection = data
            if let navigator = navigationController {
                navigator.pushViewController(vc, animated: true)
            }
        }
    }
    
    func exportGroup(_ index:Int, data:SectionsCD) {
        if clean(text: data.name!) == "" {
            alert(title: "Erroe", message: "You can't export unnamed group")
            return
        }
        
        doExportImport.exportData(section: [data],  completion: { path in
            if (path != nil) {
                fileShare(path:path!)
            } else {
                alert(title: "Error", message: "Something wrong with data")
            }
        })
    }
    
    func setVisible(_ index:Int, data:SectionsCD,state:Bool) {
        print(state)
        sectionsData[index].isVisible = ( state ) ? "1" : "0"
        data.isVisible = ( state ) ? "1" : "0"
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }

}

protocol sectionDelegate {
    func editSection(_ index:Int, data:SectionsCD)
    func addEncounterToSection(_ index:Int, data:SectionsCD)
    func updateImage(_ index:Int, data:SectionsCD)
    func exportGroup(_ index:Int, data:SectionsCD)
    func setVisible(_ index:Int, data:SectionsCD,state:Bool)
}

class sectionCell: UITableViewCell {
    var delegate:sectionDelegate?
    var index:Int = 0
    var data:SectionsCD?
    
    @IBOutlet weak var credit: UILabel!
    @IBOutlet weak var encountersLabel: UILabel!
    @IBOutlet weak var avatarHolder: UIView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var avatar: UIImageView!

    @IBOutlet weak var isVisibleLabel: UISwitch!
    @IBAction func isVivibleAction(_ sender: Any) {
        delegate?.setVisible(index, data: data!,state: isVisibleLabel.isOn )
    }
    
    @IBAction func updateImageButton(_ sender: Any) {
        delegate?.updateImage(index, data: data!)
    }
    
    @IBAction func exportButton(_ sender: Any) {
        delegate?.exportGroup(index, data: data!)
    }
    
    
    @IBAction func editAction(_ sender: Any) {
        delegate?.editSection(index, data: data!)
    }
    
    @IBOutlet weak var addEncounterlabel: UIButton!
    @IBAction func addEncounterAction(_ sender: Any) {
        delegate?.addEncounterToSection(index, data: data!)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarHolder.layer.cornerRadius = 6
    }
    
}
