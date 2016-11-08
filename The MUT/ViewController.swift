//
//  ViewController.swift
//  The MUT
//
//  Created by Michael Levenick on 10/17/16.
//  Copyright © 2016 Levenick Enterprises LLC. All rights reserved.
//

import Cocoa
import Alamofire
import CSVImporter

class ViewController: NSViewController, DataSentURL, DataSentCredentials, DataSentUsername, DataSentPath, DataSentAttributes {
    

    var globalServerURL: String!
    var globalServerCredentials: String!
    var globalCSVPath: String!
    var globalDeviceType: String!
    var globalIDType: String!
    var globalAttributeType: String!
    
    let mainViewDefaults = UserDefaults.standard
    let myFontAttribute = [ NSFontAttributeName: NSFont(name: "Consolas", size: 12.0)! ]

    
    // Declare outlets for Buttons
    @IBOutlet weak var btnServer: NSButton!
    @IBOutlet weak var btnCredentials: NSButton!
    @IBOutlet weak var btnAttribute: NSButton!
    @IBOutlet var MainViewController: NSView!

    @IBOutlet var txtMain: NSTextView!
    
    @IBOutlet weak var txtMainWrapper: NSScrollView!
    
    // Takes place right after view loads
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Restore icons if they are not null
        if mainViewDefaults.value(forKey: "ServerIcon") != nil && mainViewDefaults.value(forKey: "GlobalURL") != nil{
            let iconServer = mainViewDefaults.value(forKey: "ServerIcon") as! String
            globalServerURL = mainViewDefaults.value(forKey: "GlobalURL") as! String
            btnServer.image = NSImage(named: iconServer)
            btnCredentials.isEnabled = true
        }
        
        if mainViewDefaults.value(forKey: "UserName") != nil {
            let iconCredentials = "NSStatusPartiallyAvailable"
            btnCredentials.image = NSImage(named: iconCredentials)
        }
        
    }
    
    func printLineBreak() {
        self.txtMain.textStorage?.append(NSAttributedString(string: "\n", attributes: self.myFontAttribute))
    }
    func printString(stringToPrint: String) {
        self.txtMain.textStorage?.append(NSAttributedString(string: "\(stringToPrint)", attributes: self.myFontAttribute))
    }
    func appendLogString(stringToAppend: String) {
        self.txtMain.textStorage?.append(NSAttributedString(string: "\(stringToAppend)\n", attributes: self.myFontAttribute))
        self.txtMain.scrollToEndOfDocument(self)
    }
    func clearLog() {
        self.txtMain.textStorage?.setAttributedString(NSAttributedString(string: "", attributes: self.myFontAttribute))
    }
    
    override func viewWillAppear() {
        //resize the view
        super.viewWillAppear()
        preferredContentSize = NSSize(width: 600, height: 400)
//        txtMain.textStorage?.append(NSAttributedString(string: "Welcome to The MUT v3.0", attributes: myFontAttribute))
        
    }
    
    override func viewDidAppear() {
        if mainViewDefaults.value(forKey: "GlobalURL") == nil {
            performSegue(withIdentifier: "segueStartHere", sender: self)
            
        }
        if mainViewDefaults.value(forKey: "UserName") != nil && mainViewDefaults.value(forKey: "didDisplayNoPass") == nil {
            performSegue(withIdentifier: "segueNoPass", sender: self)
            mainViewDefaults.set("true", forKey: "didDisplayNoPass")
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


    func userDidEnterURL(serverURL: String) {
        globalServerURL = serverURL
        btnServer.image = NSImage(named: "NSStatusAvailable")
        mainViewDefaults.set(globalServerURL, forKey: "GlobalURL")
        mainViewDefaults.set("NSStatusAvailable", forKey: "ServerIcon")
        mainViewDefaults.synchronize()
        btnCredentials.isEnabled = true
    }
    
    // Pass back the base 64 encoded credentials, or auth failure
    func userDidEnterCredentials(serverCredentials: String) {
        if serverCredentials != "CREDENTIAL AUTHENTICATION FAILURE" {
            btnCredentials.image = NSImage(named: "NSStatusAvailable")
            btnAttribute.isEnabled = true
            globalServerCredentials = serverCredentials
        } else {
            btnCredentials.image = NSImage(named: "NSStatusUnavailable")
        }
    }
    
    // Pass back the Attribute information
    func userDidEnterAttributes(updateAttributes: Array<Any>) {
        btnAttribute.image = NSImage(named: "NSStatusAvailable")
        globalDeviceType = updateAttributes[0] as! String
        globalIDType = updateAttributes[1] as! String
        globalAttributeType = updateAttributes[2] as! String
        appendLogString(stringToAppend: "Device Type: \(globalDeviceType!)")
        appendLogString(stringToAppend: "ID Type: \(globalIDType!)")
        appendLogString(stringToAppend: "Attribute Type: \(globalAttributeType!)")
    }
    
    // Pass back the CSV Path
    func userDidEnterPath(csvPath: String) {
        globalCSVPath = csvPath
    }
    
    // Pass back the Username alone to store if selected
    func userDidSaveUsername(savedUser: String) {
        mainViewDefaults.set(savedUser, forKey: "UserName")
    }
    
    // Function for segue variable passing
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueServer" {
            let ServerView: ServerView = segue.destinationController as! ServerView
            ServerView.delegateURL = self
        }
        
        if segue.identifier == "segueCredentials" {
            let CredentialsView: CredentialsView = segue.destinationController as! CredentialsView
            CredentialsView.delegateCredentials = self
            CredentialsView.delegateUsername = self
            CredentialsView.representedObject = globalServerURL as String
        }
        
        if segue.identifier == "segueAttributes" {
            let AttributesView: AttributesView = segue.destinationController as! AttributesView
            AttributesView.delegatePath = self
            AttributesView.delegateAttributes = self
        }
    }
    
    @IBAction func btnClearStored(_ sender: AnyObject) {
        // Clear all stored values
        if let bundle = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundle)
        }
    }
    
    @IBAction func printInfo(_ sender: AnyObject) {
        /*var id = 560
        let endid = 580
        while id <= endid {
            let fullRequestURL = globalServerURL + "computers/id/\(id)"
            let encodedURL = NSURL(string: fullRequestURL)
            let xml = "<computer><general><name>New Swif</name></general></computer>"
            let encodedXML = xml.data(using: String.Encoding.utf8)
            var request = URLRequest(url: encodedURL as! URL)
            request.httpMethod = "PUT"
            request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
            request.addValue("Basic \(globalServerCredentials!)", forHTTPHeaderField: "Authorization")
            
            request.httpBody = encodedXML
            
            Alamofire.request(request).responseString { response in
                print ("Response String: \(response.response!.statusCode)")
                print ("URL: \(response.request!.url!)")
                self.txtNewMain.textStorage?.append(NSAttributedString(string: "\nURL: \(response.request!.url!)", attributes: self.myFontAttribute))
                self.txtNewMain.textStorage?.append(NSAttributedString(string: "\nResponse Code: \(response.response!.statusCode)", attributes: self.myFontAttribute))
                self.txtNewMain.scrollToEndOfDocument(self)
            }
            id = id + 1
        }
        */
//      let path = globalCSVPath
        let importer = CSVImporter<[String]>(path: globalCSVPath)
        importer.startImportingRecords { $0 }.onFinish { importedRecords in
            for record in importedRecords {
                
                print(record[0])
                print(record[1])
                print("break")
                self.appendLogString(stringToAppend: record[0])
                self.appendLogString(stringToAppend: record[1])
                self.appendLogString(stringToAppend: "BREAK")

            }
        }
        
        
      
    }
    @IBAction func btnClearText(_ sender: Any) {
        clearLog()
    }
}
