//
//  DTSpeechRecognition.swift
//
//  Created by Darktt on 16/12/23.
//  Copyright © 2016 Darktt. All rights reserved.
//

import Speech
import AVFoundation

@available(iOS 10.0, *)
public class DTSpeechRecognition: NSObject
{
    // MARK: - Properties -
    
    public static let supportedLocales: Array<Locale> = SFSpeechRecognizer.supportedLocales().map {$0}
    
    public var isListening: Bool {
        
        get {
            
            return self.audioEngine.isRunning
        }
    }
    
    public var availabilityChange: AvailabilityChangeHandler?
    public var recognizedHandler: RecognizedHandler?
    
    fileprivate var speechRecognizer: SFSpeechRecognizer!
    fileprivate var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    fileprivate var recognitionTask: SFSpeechRecognitionTask?
    fileprivate let audioEngine = AVAudioEngine()
    
    // MARK: - Methods -
    // MARK: Class Method
    
    public static func requestAuthorization(_ handler: @escaping RequestAuthorizationHandler)
    {
        SFSpeechRecognizer.requestAuthorization {
            
            authStatus in
            
            OperationQueue.main.addOperation {
                
                /*
                 The callback may not be called on the main thread. Add an
                 operation to the main queue to update the record button's state.
                 */
                handler(authStatus)
            }
        }
    }
    
    // MARK: Initial Method
    
    public init?(locale: Locale)
    {
        super.init()
        
        guard let speechRecognizer = SFSpeechRecognizer(locale: locale) else {
            
            return nil
        }
        
        speechRecognizer.delegate = self
        
        self.speechRecognizer = speechRecognizer
    }
    
    // MARK: Public Methods
    
    public func startListening() throws
    {
        guard !self.isListening else {
            
            return
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode: AVAudioInputNode = self.audioEngine.inputNode else {
            
            return
        }
        
        guard let recognitionRequest = self.recognitionRequest else {
            
            return
        }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        let resultHandler: (SFSpeechRecognitionResult?, Error?) -> Void = {
            
            (result, error) in
            
            var isFinal = false
            var recognitionString: String? = nil
            
            if let result = result {
                
                isFinal = result.isFinal
                recognitionString = result.bestTranscription.formattedString
            }
            
            if error != nil || isFinal {
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
            
            if let recognizedHandler = self.recognizedHandler {
                
                recognizedHandler(recognitionString, error)
            }
        }
        
        let recognitionTask: SFSpeechRecognitionTask = self.speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: resultHandler)
        
        self.recognitionTask = recognitionTask
        
        let recordingFormat: AVAudioFormat = inputNode.outputFormat(forBus: 0)
        let block: AVAudioNodeTapBlock = {
            
            (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            
            self.recognitionRequest?.append(buffer)
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat, block: block)
        
        self.audioEngine.prepare()
        try self.audioEngine.start()
    }
    
    public func stopListening()
    {
        guard self.isListening else {
            
            return
        }
        
        self.audioEngine.stop()
        self.recognitionRequest?.endAudio()
        
        // Cancel the previous task if it's running.
        self.recognitionTask?.cancel()
        self.recognitionTask = nil
    }
}

// MARK: - Delegate -

extension DTSpeechRecognition: SFSpeechRecognizerDelegate
{
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool)
    {
        guard let availabilityChange = self.availabilityChange else {
            
            return
        }
        
        availabilityChange(available)
    }
}

// MARK: - Culorse -

public extension DTSpeechRecognition
{
    typealias RequestAuthorizationHandler = (_ status: SFSpeechRecognizerAuthorizationStatus) -> Void
    typealias AvailabilityChangeHandler = (_ available: Bool) -> Void
    typealias RecognizedHandler = (_ recognitionString: String?, _ error: Error?) -> Void
}
