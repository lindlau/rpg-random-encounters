//
//  exportVC.swift
//  chat
//
//  Created by Bartosz Bibersztajn on 20/01/2018.
//  Copyright © 2018 Scairp. All rights reserved.
//

import UIKit
import CoreData
import FileProvider

class exportVC: UIViewController,UIDocumentPickerDelegate {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var sectionsData: [SectionsCD] = []
    var file:String = ""
    var url:URL?

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    
    @IBAction func dismissView(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func doBackupOfAllSections(_ sender: Any) {
        exportData(completion: { path in
            if (path != nil) {
                fileShare(path:path!)
            } else {
                alert(title: "Error", message: "Something wrong with data")
            }
        })
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if controller.documentPickerMode == UIDocumentPickerMode.import {
            // This is what it should be
            importData(file: url,completion: {success in
                
            })
        }
    }
    
    func exportData(section:[SectionsCD]? = nil, completion: (String?) -> ()) {
        sectionsData.removeAll()
        file.removeAll()
        do {
            var sectionCount:Int = 0
            var encounterCount:Int = 0
            var filename:String = "rpg-random-encounter-backup.csm"
            if section == nil {
                sectionsData = try context.fetch(SectionsCD.fetchRequest())
            } else {
                sectionsData = section!
                filename = clean(text: sectionsData[0].name!) + "-data.csm"
            }
                        
            for section in sectionsData {
                file.append("SECTION" + "[~NI]") //0
                file.append( "\(section.name ?? "")[~NI]" ) //1
                file.append( "\(section.info ?? "")[~NI]" ) //2
                if let sectionImage = section.image {
                    file.append( sectionImage.base64EncodedString() ) //3
                }
                file.append("[~NI]")
                file.append( "\(section.credit ?? "")[~NI]" ) //4
                file.append("[~NL]\n")
                sectionCount += 1
                for item in section.toItems?.allObjects as! [ItemsCD] {
                    file.append("ENCOUNTER" + "[~NI]") //0
                    file.append( "\(item.name ?? "")[~NI]" ) //1
                    file.append( "\(item.info ?? "")[~NI]" ) //2
                    file.append( "\(item.probability)[~NI]" ) //3
                    if let itemImage = item.image {
                        file.append( itemImage.base64EncodedString() ) //4
                    }
                    file.append("[~NI]")
                    file.append( "\(item.credit ?? "")[~NI]" ) //5
                    file.append("[~NL]\n")
                    encounterCount += 1
                }
            }
            if let path:String = writeToDocumentsFile(fileName: filename , value: file) {
                completion(path)
            } else {
                completion(nil)
            }
        } catch {
            print("Fetching Failed")
            completion(nil)
        }
    }
    
    
    func importData(file:URL?, completion: (Bool) -> ()) {
        var sectionCount:Int = 0
        var encounterCount:Int = 0
        
        var data:String = ""
        if FileManager.default.fileExists(atPath: (file?.path)! ){
            if let cert = NSData(contentsOfFile: (file?.path)! ) {
                guard let fileContent:String = NSString(data: cert as Data, encoding: String.Encoding.utf8.rawValue) as String? else {
                    self.alert(title: "Error", message: "Wrong file formt")
                    completion(false)
                    return
                }
                data = fileContent
            }
        } else {
            data = readFromDocumentsFile(fileName:"data.csm")
        }
        
        var result: [[String]] = []
        let rows = data.components(separatedBy: "[~NL]\n")
        for row in rows {
            let columns = row.components(separatedBy: "[~NI]")
            result.append(columns)
        }
        var currentSection:SectionsCD?
        for respone in result {
            if respone.indices.contains(0) && respone.indices.contains(1) {
                if respone[0] == "SECTION" {
                    currentSection = SectionsCD(context: context) // Link Task & Context
                    currentSection?.name = respone[1]
                    currentSection?.isVisible = "1"
                    currentSection?.image = converBase64ToImage(string: respone[3] )
                    currentSection?.credit = respone[4]
                    sectionCount += 1
                    print("HEEEEREEEE")
                    if avatar != nil {
                        if let presentImage:UIImage = UIImage(data: converBase64ToImage(string: respone[3])! ) {
                            avatar.image = presentImage
                        } else {
                            avatar.image = #imageLiteral(resourceName: "re-1024")
                        }
                    }
                    if name != nil {
                        name.text = respone[1]
                    }
                } else if respone[0] == "ENCOUNTER" {
                    let item = ItemsCD(context: context) // Link Task & Context
                    item.name = respone[1]
                    item.info = respone[2]
                    item.credit = respone[5]
                    if respone.indices.contains(3) {
                        item.probability = ( Float(respone[3]) != nil ) ? Float(respone[3])! : 0.01
                    }
                    item.image = converBase64ToImage(string: respone[4] )
                    item.toSections = currentSection
                    encounterCount += 1
                }
            }
        }
        if info != nil {
            info.text = "\(encounterCount) Encounters"
        }
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        completion(true)
    }
    
    func writeToDocumentsFile(fileName:String,value:String) -> String? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString!
        let path = documentsPath?.appendingPathComponent("/\(fileName)")
    
        do {
            try value.write(toFile: path!, atomically: false, encoding: String.Encoding.utf8)
            return path
        } catch let error as NSError {
            print("ERROR : writing to file \(path ?? "") : \(error.localizedDescription)")
            return nil
        }
    }
    
    func getDirectoryPath() -> NSString {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        return documentsPath
    }
    
    func readFromDocumentsFile(fileName:String) -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let path = documentsPath.appendingPathComponent(fileName)
        var readText : String = ""
        do {
            try readText = NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String
        }
        catch let error as NSError {
            print("ERROR : reading from file \(fileName) : \(error.localizedDescription)")
        }
        return readText
    }

    func converBase64ToImage(string:String) -> Data? {
        let dataDecoded:Data? = Data(base64Encoded: string , options: .ignoreUnknownCharacters)
        return dataDecoded
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if url != nil {
            importData(file: url, completion: {success in})
        }
        name.dropShadow()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}

func clean(text: String) -> String {
    let okayChars : Set<Character> =
        Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890_")
    return String(text.filter {okayChars.contains($0) })
}

extension UIViewController {
    func alert(title:String = "",message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func fileShare(path:String){
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path){
            let documento = NSURL(fileURLWithPath: path)
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [documento], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView=self.view
            present(activityViewController, animated: true, completion: nil)
        }
        else {
            print("document was not found")
        }
    }
}


let doExportImport:exportVC = exportVC()
