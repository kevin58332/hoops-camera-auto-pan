//
//  ViewController.swift
//  ball-tracker
//
//  Created by Kevin Aguilar on 7/21/22.
//

import UIKit
import Foundation
import UIKit
import AVFoundation
import Vision
import Photos

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let captureSession = AVCaptureSession()
    let scrollView = UIScrollView()
    var previewLayer: AVCaptureVideoPreviewLayer
    var resButtonState = false
    private let videoOutput = AVCaptureVideoDataOutput()
    let boundingBox = UIView()
    
    let model: yolov5s = {
    do {
        let config = MLModelConfiguration()
        return try yolov5s(configuration: config)
    } catch {
        print(error)
        fatalError("Couldn't create yolov5s")
    }
    }()
  

    func viewIsLive() {
        self.addVideoOutput()
        captureSession.startRunning()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let orientation: UIDeviceOrientation = UIDevice.current.orientation
        previewLayer.connection?.videoOrientation = {
            switch orientation {
            case .landscapeRight:
                return .landscapeLeft
            case .landscapeLeft:
                return .landscapeRight
            default:
                return .landscapeRight
            }
        }()
        
    
    }


    override func viewWillLayoutSubviews() {
        
        
        let rect = AVMakeRect(aspectRatio: CGSize(width: 16, height: 9), insideRect: view.bounds)

        view.bounds = rect
        
        scrollView.frame = self.view.frame

        
        if resButtonState {
            self.previewLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width*2, height: view.bounds.height*2)
        }else{
            self.previewLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width*3, height: view.bounds.height*3)

        }
        
        
        
        scrollView.contentSize = CGSize(width: self.previewLayer.frame.width, height: self.previewLayer.frame.height)
        scrollView.isScrollEnabled = false
        scrollView.setContentOffset(CGPoint(x: self.previewLayer.frame.midX - self.view.frame.width/2, y: self.previewLayer.frame.midY - self.view.frame.height/2), animated: true)
        
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(scrollView)
        
        
        // Setting up camera on 4k wide angle with landscape orientation
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        captureSession.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
        guard let captureDevice = AVCaptureDevice.default(.builtInUltraWideCamera,
                                                          for: AVMediaType.video, position: .back) else { return }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
                
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill

        scrollView.layer.addSublayer(previewLayer)
        
        //Starting video
        viewIsLive()

        
        
        //setting up button to change resolution
//        let resButton = UIButton(type: .custom)
//        resButton.frame = CGRect(x: UIScreen.main.bounds.maxX - 100, y: 75, width: 50, height: 50)
//        resButton.setTitle("Res", for: .normal)
//        resButton.backgroundColor = UIColor.blue
//        resButton.setTitleColor(UIColor.white, for: .normal)
//        resButton.addTarget(self, action: #selector(resButtonPressed),
//                            for: .touchDown)
//        self.view.addSubview(resButton)
        
       
        
        
        

        boundingBox.layer.borderWidth = 4
        boundingBox.backgroundColor = .clear
        boundingBox.layer.borderColor = UIColor.blue.cgColor
        scrollView.addSubview(boundingBox)
    }
    
    
    func moveLeft(boxX: CGFloat){
        if(boxX - self.view.frame.width/2 > 0){
            scrollView.setContentOffset(CGPoint(x: boxX - self.view.frame.width/2, y: self.previewLayer.frame.midY - self.view.frame.height/2), animated: true)
        }
    }
    

    
    func moveRight(boxX:CGFloat){
        //self.previewlayer.frame.width if black bars aren't on the sides
        if(boxX + self.view.frame.width/2 < self.previewLayer.frame.maxX){
            scrollView.setContentOffset(CGPoint(x: boxX - self.view.frame.width/2, y: self.previewLayer.frame.midY - self.view.frame.height/2), animated: true)
        }
    }
    
    @objc func resButtonPressed() {
        resButtonState.toggle()
        viewWillLayoutSubviews()
        
    }


    required init?(coder aDecoder: NSCoder) {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init(coder: aDecoder)
    }



    private func addVideoOutput() {
        self.videoOutput.videoSettings =
        [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "my.image.handling.queue"))
        self.captureSession.addOutput(self.videoOutput)
    }

    func captureOutput(_ output: AVCaptureOutput,
                           didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection) {
            guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                debugPrint("unable to get image from sample buffer")
                return
            }
            let ciimage = CIImage(cvImageBuffer: frame)
            let context = CIContext()
            if let cgImage = context.createCGImage(ciimage, from: ciimage.extent) {

                let uiImage = UIImage(cgImage: cgImage)
                //Resizing image so that model works properly
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 640, height: 640))
                let testImage = renderer.image{(context) in
                    uiImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 640, height: 640)))
                }
                
                self.classify(image: testImage)

            }
        
        }
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do{
            let vnModel = try VNCoreMLModel(for: self.model.model)
            let request = VNCoreMLRequest(model: vnModel){ [unowned self] request, _ in
                self.processObservations(for: request)
            }
            return request
        }catch{
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    func processObservations(for request: VNRequest){
        
        DispatchQueue.main.async {
            
            var numOfPeople: CGFloat = 0
            var totalX: CGFloat = 0
            
            let people = request.results?.filter{it in
                if let p = it as? VNRecognizedObjectObservation{
                    if p.labels.first?.identifier == "person"{
                        numOfPeople = numOfPeople + 1
                        return true
                    }
                }
                return false
            }
                        
            people?.forEach{ it in
                if let person = it as? VNRecognizedObjectObservation{
                    totalX = totalX + person.boundingBox.midX
                }
            }
            
            let avgX = (totalX/numOfPeople)*self.previewLayer.frame.width
            
            if UIScreen.main.bounds.midX > avgX{
                let diff = UIScreen.main.bounds.midX - avgX
                if(diff > 20){
                    self.moveLeft(boxX: avgX)
                }
            }else{
                let diff = avgX - UIScreen.main.bounds.midX
                if(diff > 20){
                    self.moveRight(boxX: avgX)
                }
            }
            
            
            
            
            
//            if !(request.results ?? []).isEmpty{
//                if let result = request.results?.first as? VNRecognizedObjectObservation{
//                    if result.labels.first?.identifier == "person" {
//
//                        let rect = CGRect(x: (result.boundingBox.minX * self.previewLayer.frame.width) + self.previewLayer.frame.minX, y: self.previewLayer.frame.maxY - (result.boundingBox.minY * self.previewLayer.frame.height) - (result.boundingBox.height*self.previewLayer.frame.height), width: result.boundingBox.width * self.previewLayer.frame.width, height: result.boundingBox.height * self.previewLayer.frame.height)
//
//
//                        if UIScreen.main.bounds.midX > rect.midX{
//                            let diff = UIScreen.main.bounds.midX - rect.midX
//                            if(diff > 50){
//                                self.moveLeft(boxX: rect.midX)
////                                print("left")
////                                print(self.previewLayer.frame.minX)
//                            }
//                        }else{
//                            let diff = rect.midX - UIScreen.main.bounds.midX
//                            if(diff > 50){
//                                self.moveRight(boxX: rect.midX)
////                                print("right")
////                                print(self.previewLayer.frame.minX)
//                            }
//                        }
//
//                        self.boundingBox.frame = rect
//
//                    }
//                }
//            }
        }
    }
    
    func classify(image: UIImage){
                
        DispatchQueue.global(qos: .userInitiated).async {
            if let ciImage = CIImage(image: image){
                let handler = VNImageRequestHandler(ciImage: ciImage, orientation: .up)
                do {
                    try handler.perform([self.classificationRequest])
                }catch{
                    print(error)
                }
            }
        }
    }

}

