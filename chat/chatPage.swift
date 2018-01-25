//
//  chatPage.swift
//  chat
//
//  Created by Bartosz Bibersztajn on 10/01/2018.
//  Copyright © 2018 Scairp. All rights reserved.
//  MTG

import UIKit
import AVFoundation
import CoreData

var player: AVAudioPlayer?

func playSound() {
    guard let url = Bundle.main.url(forResource: "dice", withExtension: "mp3") else { return }
    do {
        try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try AVAudioSession.sharedInstance().setActive(true)
        player = try AVAudioPlayer(contentsOf: url)
        guard let player = player else { return }
        player.play()
    } catch let error {
        print(error.localizedDescription)
    }
}

let screenWidth:CGFloat = UIScreen.main.bounds.width

class chatPage: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,rootViewProtocol {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var sectionsData: [SectionsCD] = []
    
    enum UIUserInterfaceIdiom : Int {
        case unspecified
        case phone // iPhone and iPod touch style UI
        case pad // iPad style UI
    }
    
    @IBOutlet weak var tokenCollection: UICollectionView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var plusButton: UIButton!
    
    
    @IBOutlet weak var preloadDefaultdataLabel: UIButton!
    @IBAction func preloadDataAction(_ sender: Any) {
        if let path:String = Bundle.main.path(forResource: "defaultData", ofType: "csm") {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = mainStoryboard.instantiateViewController(withIdentifier: "exportVC") as! exportVC
            vc.url = URL(fileURLWithPath: path)
            vc.modalTransitionStyle = .partialCurl
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sectionsData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! cell
        let data = sectionsData[indexPath.row]
        let itemsCount:Int = data.toItems!.allObjects.count
        
        cell.backImage.image = #imageLiteral(resourceName: "re-1024")
        cell.backTitle.text = "No encounters yet"
        cell.backMessage.text = "Add some encouters, and you will be able to select them randomly when you roll here."
        
        if  itemsCount > 0 {
            cell.counterLabel.text = "\(itemsCount) Encounters"
        } else {
            cell.counterLabel.text = ""
        }
        
        cell.frontImage.image = #imageLiteral(resourceName: "re-1024")
        if data.image != nil {
            cell.frontImage.image = UIImage(data: data.image!)
        }
        cell.name.text = data.name
        cell.credit.text = data.credit

        flippedCells[indexPath.row] = false
        cell.frontView.isHidden = false
        cell.backView.isHidden = true
        
        cell.currentCell = indexPath.row
        cell.currentSection = data
        cell.delegate = self
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width:CGFloat = 0
        var height:CGFloat = 0
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            width = screenWidth
            height = screenWidth
            break
        case .pad:
            width = screenWidth / 2
            height = screenWidth / 2
            break
        default:
            width = screenWidth
            height = screenWidth
        }
        return CGSize(width: width, height: height)
    }
    
    func rollDice(_ index: Int,_ element:SectionsCD) {
        turnPage(index,element)
    }
    
    var flippedCells:[Int:Bool] = [0:false]
    func turnPage(_ index:Int,_ element:SectionsCD) {
        if flippedCells[index] == nil {
            flippedCells[index] = false
        }
        
        let cell = tokenCollection.cellForItem(at: [0,index] ) as! cell
        let transitionOptions:UIViewAnimationOptions = [.transitionFlipFromLeft, .showHideTransitionViews]
        var firstVC = cell.frontView
        var secondVC = cell.backView
        cell.rollDiceLabel.isEnabled = false
        if flippedCells[index]! {
            firstVC = cell.backView
            secondVC = cell.frontView
            flippedCells[index] = false
        } else {
            playSound()
            flippedCells[index] = true
            loadSideTwo(index,element,cell)
        }
        UIView.transition(with: firstVC!, duration: 0.6, options: transitionOptions, animations: {
            firstVC?.isHidden = true
        })
        
        UIView.transition(with: secondVC!, duration: 0.6, options: transitionOptions, animations: {
            secondVC?.isHidden = false
        }, completion:{ _ in
            cell.rollDiceLabel.isEnabled = true
        })
    }
    
    func loadSideTwo(_ index:Int,_ element:SectionsCD,_ cell:cell){
        let currentElements:[ItemsCD] = element.toItems?.allObjects as! [ItemsCD]
        if currentElements.count > 0 {
            struct probabiltyList {
                let from: Int
                let to: Int
                let item:ItemsCD
            }
            var rollForEmelemnts:[probabiltyList] = []
            var probabilityMin:Int = 0
            var probabilityMax:Int = 0
            for element in currentElements {
                probabilityMax = Int(element.probability * 1000) + probabilityMax
                rollForEmelemnts.append(probabiltyList.init(from: probabilityMin, to: probabilityMax, item: element))
                probabilityMin = Int(element.probability * 1000) + probabilityMin
            }
            
            if probabilityMax < 1 {
                return
            }
            
            let roll:Int = Int(arc4random_uniform( UInt32(probabilityMax) ))
            print(roll)
            
            var showElement:ItemsCD? = nil
            for element in rollForEmelemnts {
                if element.from <= roll && element.to >= roll {
                    showElement = element.item
                    break
                }
            }
            
            let probabilityColor:Float = showElement?.probability ?? 0.8
            
            if probabilityColor < 0.11 {
                cell.probabilityLabel.textColor = #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)
                cell.probabilityLabel.text = "Unique"
            } else if probabilityColor < 0.21 {
                cell.probabilityLabel.textColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
                cell.probabilityLabel.text = "Rare"
            } else if probabilityColor < 0.81 {
                cell.probabilityLabel.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
                cell.probabilityLabel.text = ""
            } else {
                cell.probabilityLabel.textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
                cell.probabilityLabel.text = ""
            }
            
            cell.backTitle.text = showElement?.name
            cell.backMessage.text = showElement?.info
            if showElement?.image != nil {
                cell.backImage.image = UIImage(data: (showElement?.image)!)
            }
        }
    }
    
    @IBOutlet weak var settingLabel: UIButton!
    @IBAction func toggleHelpButton(_ sender: Any) {
        toggleHelp()
    }
    
    func toggleHelp() {
        if helpHolder.isHidden == true {
            helpHolder.isHidden = false
            settingLabel.setTitle( "╳" , for: .normal)
            self.helpHolder.alpha = 0
            UIView.animate(withDuration: 0.2, animations: {
                self.helpHolder.alpha = 1
            },completion:{_ in })
        } else {
            settingLabel.setTitle("⚙︎", for: .normal)
            UIView.animate(withDuration: 0.2, animations: {
                self.helpHolder.alpha = 0
            },completion:{_ in
                self.helpHolder.isHidden = true
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tokenCollection.delegate = self
        tokenCollection.dataSource = self
        plusButton.layer.cornerRadius = 25
        settingLabel.layer.cornerRadius = 25
        preloadDefaultdataLabel.layer.cornerRadius = 25
        versionAndBuild.text = "Version \(app_version).\(app_build)"
        
        let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontalMotionEffect.minimumRelativeValue = -10
        horizontalMotionEffect.maximumRelativeValue = 10
        
        let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        verticalMotionEffect.minimumRelativeValue = 10
        verticalMotionEffect.maximumRelativeValue = -10
        
        let motionEffectGroup = UIMotionEffectGroup()
        motionEffectGroup.motionEffects = [horizontalMotionEffect, verticalMotionEffect]
        
        plusButton.addMotionEffect(motionEffectGroup)
        settingLabel.addMotionEffect(motionEffectGroup)
        
   }

    func getData() {
        do {
            let request:NSFetchRequest<SectionsCD> = SectionsCD.fetchRequest()
            request.predicate = NSPredicate(format: "isVisible == %@", "1")
            
            sectionsData = try context.fetch( request )
            tokenCollection.reloadData()
            if sectionsData.count > 0 {
                emptyView.isHidden = true
                preloadDefaultdataLabel.isHidden = true
                //itemTable.scrollToRow(at: [0,items.count - 1] , at: .bottom, animated: true)
            } else {
                emptyView.isHidden = false
                preloadDefaultdataLabel.isHidden = false
            }
        } catch {
            print("Fetching Failed")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        getData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.title = " "
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //================================== help page
    @IBOutlet weak var helpHolder: UIVisualEffectView!
    @IBOutlet weak var versionAndBuild: UILabel!
    let app_version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    let app_build = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    
    @IBOutlet weak var helpStack: UIStackView!
    
    var appId:String = "id1338296391"
    @IBAction func support(_ sender: Any) {
        openURL(link: "https://goo.gl/forms/kG4m1fbZ0DbsUnJA2")
    }
    @IBAction func rateUs(_ sender: Any) {
        rateApp(appId: appId ) { success in
        }
    }

    @IBAction func shareAppAction(_ sender: Any) {
        share()
    }
    func share() {
        //Set the default sharing message.
        let message = "Random Encounters."
        //Set the link to share.
        if let link = NSURL(string: "https://itunes.apple.com/gb/app/rpg-dice-roller-lite/\(appId)")
        {
            let objectsToShare = [message,link] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func buyMeABeer(_ sender: Any) {
        openURL(link: "https://www.paypal.me/whichapp")
    }

    var isIdleTimerDisabled:Bool = false
    @IBAction func screenlockaction(_ sender: UIButton) {
        isIdleTimerDisabled = (isIdleTimerDisabled) ? false : true
        sender.setTitle( ((isIdleTimerDisabled) ? "❦  Auto lock OFF" : "❦  Auto lock ON" ) , for: .normal)
        UIApplication.shared.isIdleTimerDisabled = isIdleTimerDisabled
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
            showBottomButton()
        }
        if (scrollView.contentOffset.y <= 0){
            showBottomButton()
        }
        if (scrollView.contentOffset.y > 0 && scrollView.contentOffset.y < (scrollView.contentSize.height - scrollView.frame.size.height)){
            hideBottomButton()
        }
    }
    
    func hideBottomButton() {
        UIView.animate(withDuration: 0.3, delay:0.0, options: [.curveEaseInOut] , animations: {
            self.plusButton.transform = CGAffineTransform(translationX: 160, y: 0)
            self.settingLabel.transform = CGAffineTransform(translationX: 160, y: 0)
        })
    }
    func showBottomButton() {
        UIView.animate(withDuration: 0.3, delay:0.0, options: [.curveEaseInOut] , animations: {
            self.plusButton.transform = CGAffineTransform(translationX: 0, y: 0)
            self.settingLabel.transform = CGAffineTransform(translationX: 0, y: 0)
        })
    }
    
}

protocol rootViewProtocol {
    func rollDice(_ index:Int,_ element:SectionsCD)
}

class cell:UICollectionViewCell {
    var delegate:rootViewProtocol?
    var currentSection:SectionsCD?
    var currentCell:Int = 0
    
    @IBOutlet weak var credit: UILabel!
    @IBOutlet weak var probabilityLabel: UILabel!
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var frontImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var counterLabel: UILabel!
    
    @IBOutlet weak var backTitle: UILabel!
    @IBOutlet weak var backImage: UIImageView!
    @IBOutlet weak var backMessage: UILabel!
    
    @IBOutlet weak var rollDiceLabel: UIButton!
    @IBAction func rollDIce(_ sender: Any) {
        delegate?.rollDice(currentCell,currentSection!)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backView.layer.cornerRadius = 6
        frontView.layer.cornerRadius = 6
        //counter.dropShadow(offset: CGSize(width: 3, height: 3), radius: 50, opacity: 0.6)
    }
}
