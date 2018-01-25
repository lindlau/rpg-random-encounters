//
//  ViewController.swift
//  chat
//
//  Created by Bartosz Bibersztajn on 18/01/2018.
//  Copyright © 2018 Scairp. All rights reserved.
//

import UIKit
import AVFoundation

extension UIView {
    func dropShadow(_ color:UIColor = .black,offset:CGSize = CGSize(width:2,height:2) ,radius:CGFloat = 4,opacity:Float = 0.5  ) {
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
        self.layer.shadowOpacity = opacity
    }
}

func openURL(link:String) {
    guard let url = URL(string: link) else {
        return //be safe
    }
    if #available(iOS 10.0, *) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    } else {
        UIApplication.shared.openURL(url)
    }
}

func rateApp(appId: String, completion: @escaping ((_ success: Bool)->())) {
    guard let url = URL(string : "itms-apps://itunes.apple.com/app/" + appId) else {
        completion(false)
        return
    }
    guard #available(iOS 10, *) else {
        completion(UIApplication.shared.openURL(url))
        return
    }
    UIApplication.shared.open(url, options: [:], completionHandler: completion)
}

func playSound(resource:String) {
    guard let url = Bundle.main.url(forResource: resource, withExtension: "mp3") else { return }
    
    do {
        
        try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try AVAudioSession.sharedInstance().setActive(true)
        player = try AVAudioPlayer(contentsOf: url)
        guard let player = player else { return }
        player.stop()
        let seconds = 0.3//Time To Delay
        let when = DispatchTime.now() + seconds
        
        DispatchQueue.main.asyncAfter(deadline: when) {
            player.play()
        }
        
    } catch let error {
        print(error.localizedDescription)
    }
}

extension UIView {
    func roundCorners(_ corners:UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}

func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size
    
    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height
    
    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize(width: size.width * widthRatio, height:  size.height * widthRatio)
    }
    
    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x:0, y:0, width: newSize.width, height:  newSize.height)
    
    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage!
}


