//
//  ViewController.swift
//  SpeechRecognition
//
//  Created by Darktt on 2016/12/23.
//  Copyright © 2016 Darktt. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    var locales: Array<Locale> = DTSpeechRecognition.supportedLocales
    let currentLocale: Locale = Locale.current
    
    var speechRecognition: DTSpeechRecognition?
    
    @IBOutlet fileprivate weak var pickerView: UIPickerView!
    @IBOutlet fileprivate weak var textView: UITextView!
    @IBOutlet fileprivate weak var listenButton: UIButton!
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        DTSpeechRecognition.requestAuthorization {
            
            status in
            
            switch status {
            case .authorized:
                self.listenButton.isEnabled = true
                
            case .denied:
                self.listenButton.isEnabled = false
                self.listenButton.setTitle("User denied access to speech recognition", for: .disabled)
                
            case .restricted:
                self.listenButton.isEnabled = false
                self.listenButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                
            case .notDetermined:
                self.listenButton.isEnabled = false
                self.listenButton.setTitle("Speech recognition not yet authorized", for: .disabled)
            }
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.textView.text = ""
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
         
        if let index = self.locales.index(of: self.currentLocale) {
            
            self.pickerView.selectedRow(inComponent: index)
        }
        
        self.setupSpeechRecognition(for: self.currentLocale)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}

// MARK: - Actions -

fileprivate extension ViewController
{
    @objc @IBAction
    fileprivate func startListenAction(_ sender: UIButton)
    {
        guard let speechRecognition = self.speechRecognition, !speechRecognition.isListening else {
            
            self.speechRecognition?.stopListening()
            
            sender.setTitle("Start Listen", for: .normal)
            return
        }
        
        do {
            
            try speechRecognition.startListening()
            
            sender.setTitle("Listening...", for: .normal)
        } catch {
            
            print(error)
        }
    }
}

// MARK: - Private -

fileprivate extension ViewController
{
    fileprivate func setupSpeechRecognition(for locale: Locale)
    {
        let speechRecognition = DTSpeechRecognition(locale: locale)
        
        self.speechRecognition = speechRecognition
    }
}

// MARK: - Delegate -

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate
{
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return self.locales.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        let title: String = {
            
            let locale = self.locales[row]
            
            return locale.identifier
        }()
        
        return title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        let locale = self.locales[row]
        
        self.setupSpeechRecognition(for: locale)
    }
}

