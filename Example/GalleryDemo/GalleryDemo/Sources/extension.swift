//
//  extension.swift
//  GalleryDemo
//
//  Created by Armen Alex on 07.05.21.
//  Copyright © 2021 Hyper Interaktiv AS. All rights reserved.
//
import Foundation

extension String {
    
    static func getEditorParameterFormat(min: CGFloat, max: CGFloat) -> String {
        let delta = max - min
        if delta > 20 {
            return "%.0f"
        } else if delta >= 10 {
            return "%.1f"
        } else {
            return "%.2f"
        }
    }
    
    static func randomString(length:Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
        
    }
    
    func spaceReplaced() -> String {
        return String(self.map {
            $0 == " " ? "+" : $0
        })
    }
    
    
    
    static func setRealmPath(path: String, folderName: String) -> String {
        guard let name = path.split(separator: "/").last  else {
            return path
        }
        
        let fileManager = FileManager.default
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let recordDirectory = documentDirectory.appendingPathComponent(folderName)
            
            let url = recordDirectory.appendingPathComponent(String(name))
            return url.path
        } catch (let error) {
            print(error.localizedDescription)
            return path
        }
    }
    
    var numberValue: NSNumber? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.number(from: self)
    }
    
    func substring(with nsrange: NSRange) -> Substring? {
        guard let range = Range(nsrange, in: self) else {
            return nil
        }
        return self[range]
    }
}


extension String {
    func dictionaryValue() -> [String: AnyObject]? {
        if let data = self.data(using: String.Encoding.utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]
                return json
                
            } catch {
                print("Error converting to JSON")
            }
        }
        return nil
    }
}

extension NSDictionary{
    func JsonString() -> String {
        do {
            let jsonData: Data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String.init(data: jsonData, encoding: .utf8)!
        }
        catch
        {
            return "error converting"
        }
    }
}




import UIKit
import Photos

let AlbumTitle = "Zoomerang"
let TutorialTitle = "Tutorial"


class VideoFileManager: NSObject {
  
  
  static let sharedInstance = VideoFileManager()
  
  static func getRandomVideoUrl(folderName: String) -> URL? {
    let fileManager = FileManager.default
    var fileURL: URL?
    do {
      let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      
      let recordDirectory: URL = documentDirectory.appendingPathComponent(folderName)
      
      if !fileManager.fileExists(atPath: recordDirectory.path) {
        try fileManager.createDirectory(at: recordDirectory, withIntermediateDirectories: true, attributes: nil)
      }
      
      fileURL = recordDirectory.appendingPathComponent("\(String.randomString(length: 10)).mov")
      
      
    } catch let error {
      print("Error ",error.localizedDescription)
    }
    
    return fileURL
    
  }
}
