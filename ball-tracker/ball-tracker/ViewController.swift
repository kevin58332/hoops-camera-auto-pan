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
//    let scrollView = UIScrollView()
    let imageView = UIImageView()
    var previewLayer: AVCaptureVideoPreviewLayer
    var resButtonState = false
    private let videoOutput = AVCaptureVideoDataOutput()
    let boundingBox = UIView()
    
    let model: yolov5s_original_ane = {
    do {
        let config = MLModelConfiguration()
        return try yolov5s_original_ane(configuration: config)
    } catch {
        print(error)
        fatalError("Couldn't create yolov5s")
    }
    }()
  

    func viewIsLive() {
        self.addVideoOutput()
        DispatchQueue.global(qos: .background).async { self.captureSession.startRunning() }
    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//        let orientation: UIDeviceOrientation = UIDevice.current.orientation
//        previewLayer.connection?.videoOrientation = {
//            switch orientation {
//            case .landscapeRight:
//                return .landscapeLeft
//            case .landscapeLeft:
//                return .landscapeRight
//            default:
//                return .landscapeRight
//            }
//        }()
//
//
//    }


    override func viewWillLayoutSubviews() {
        
        
//        let rect = AVMakeRect(aspectRatio: CGSize(width: 16, height: 9), insideRect: view.bounds)
//
//        view.bounds = rect
        
//        scrollView.frame = self.view.frame

//        previewLayer.frame = self.view.frame
//        if resButtonState {
//            self.previewLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width*2, height: view.bounds.height*2)
//        }else{
//            self.previewLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width*3, height: view.bounds.height*3)
//
//        }
        
        
        
//        scrollView.contentSize = CGSize(width: self.previewLayer.frame.width, height: self.previewLayer.frame.height)
//        scrollView.isScrollEnabled = false
//        scrollView.setContentOffset(CGPoint(x: self.previewLayer.frame.midX - self.view.frame.width/2, y: self.previewLayer.frame.midY - self.view.frame.height/2), animated: true)
        
        
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        let rect = AVMakeRect(aspectRatio: CGSize(width: 16, height: 9), insideRect: view.bounds)
//            view.bounds = rect
        
        //// uncomment if using previewlayer
//        self.previewLayer.frame = rect
        self.imageView.frame = rect
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let connection = self.previewLayer.connection {
            let currentDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection: AVCaptureConnection = connection
            
            if previewLayerConnection.isVideoOrientationSupported {
                switch orientation {
                case .portrait: self.updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                case .landscapeRight: self.updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                case .landscapeLeft: self.updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                case .portraitUpsideDown: self.updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                default: self.updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                }
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.view.addSubview(scrollView)
//        let rect = AVMakeRect(aspectRatio: CGSize(width: 16, height: 9), insideRect: view.bounds)
//        view.bounds = rect
//        self.previewLayer.frame=self.view.layer.bounds
        
        // Setting up camera on 4k wide angle with landscape orientation
//        let value = UIInterfaceOrientation.landscapeRight.rawValue
//        UIDevice.current.setValue(value, forKey: "orientation")
        
        captureSession.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
        guard let captureDevice = AVCaptureDevice.default(.builtInUltraWideCamera,
                                                          for: AVMediaType.video, position: .back) else { return }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
          
        //// uncomment if using previewlayer
//        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        previewLayer.frame = view.frame
//        previewLayer.videoGravity = .resizeAspectFill
//        view.layer.addSublayer(previewLayer)

        
        
        
        
        
//        scrollView.layer.addSublayer(previewLayer)
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
        
       
        
//        imageView.frame = CGRect(x: UIScreen.main.bounds.maxX - 100, y: 75, width: 50, height: 50)
        imageView.frame = view.frame
//        imageView.frame = AVMakeRect(aspectRatio: CGSize(width: 16, height: 9), insideRect: view.bounds)
        self.view.addSubview(imageView)
        

        boundingBox.layer.borderWidth = 4
        boundingBox.backgroundColor = .clear
        boundingBox.layer.borderColor = UIColor.blue.cgColor
//        scrollView.addSubview(boundingBox)
    }
    
    
//    func moveLeft(boxX: CGFloat){
//        if(boxX - self.view.frame.width/2 > 0){
//            scrollView.setContentOffset(CGPoint(x: boxX - self.view.frame.width/2, y: self.previewLayer.frame.midY - self.view.frame.height/2), animated: true)
//        }
//    }
    

    
//    func moveRight(boxX:CGFloat){
//        //self.previewlayer.frame.width if black bars aren't on the sides
//        if(boxX + self.view.frame.width/2 < self.previewLayer.frame.maxX){
//            scrollView.setContentOffset(CGPoint(x: boxX - self.view.frame.width/2, y: self.previewLayer.frame.midY - self.view.frame.height/2), animated: true)
//        }
//    }
    
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
                
                
//                let layer = CAShapeLayer()
//                let path = UIBezierPath()
//                path.move(to: CGPoint(x: 40, y: 40))
//                path.addLine(to: CGPoint(x: 150, y: 40))
//                path.addLine(to: CGPoint(x: 200, y: 100))
//                path.addLine(to: CGPoint(x: 20, y: 100))
//                path.close()
//                layer.path = path.cgPath
//                layer.fillColor = UIColor.red.cgColor
//                layer.backgroundColor = UIColor.blue.cgColor
//
//                layer.contents = uiImage.cgImage
//                self.imageView.layer.mask = layer
                guard let maskImage = drawOnImage(uiImage) else { return }
           
                
                
                //Resizing image so that model works properly
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 640, height: 640))
                let testImage = renderer.image{(context) in
                    uiImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 640, height: 640)))
                }
                DispatchQueue.main.async { [weak self] in
                    guard let welf = self else { return }
                    welf.imageView.image = uiImage

                }
                self.classify(image: testImage)

            }
        
        }
    
    func drawOnImage(_ image: UIImage) -> UIImage? {
         
         // Create a context of the starting image size and set it as the current one
         UIGraphicsBeginImageContext(image.size)
         
         // Draw the starting image in the current context as background
         image.draw(at: CGPoint.zero)

         // Get the current context
         let context = UIGraphicsGetCurrentContext()!

         // Draw a red line
         context.setLineWidth(2.0)
         context.setStrokeColor(UIColor.red.cgColor)
         context.move(to: CGPoint(x: 100, y: 100))
         context.addLine(to: CGPoint(x: 200, y: 200))
         context.strokePath()
         
         // Draw a transparent green Circle
         context.setStrokeColor(UIColor.green.cgColor)
         context.setAlpha(0.5)
         context.setLineWidth(10.0)
         context.addEllipse(in: CGRect(x: 100, y: 100, width: 100, height: 100))
         context.drawPath(using: .stroke) // or .fillStroke if need filling
         
         // Save the context as a new UIImage
         let myImage = UIGraphicsGetImageFromCurrentImageContext()
         UIGraphicsEndImageContext()
         
         // Return modified image
         return myImage
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
            
//            let avgX = (totalX/numOfPeople)*self.previewLayer.frame.width
            
//            if UIScreen.main.bounds.midX > avgX{
//                let diff = UIScreen.main.bounds.midX - avgX
//                if(diff > 20){
//                    self.moveLeft(boxX: avgX)
//                }
//            }else{
//                let diff = avgX - UIScreen.main.bounds.midX
//                if(diff > 20){
//                    self.moveRight(boxX: avgX)
//                }
//            }
            
            
            
            
            
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

