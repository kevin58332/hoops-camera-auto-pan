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
import MobileCoreServices

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    let captureSession = AVCaptureSession()
    let imageView = UIImageView()
    var previewLayer: AVCaptureVideoPreviewLayer
    private let videoOutput = AVCaptureVideoDataOutput()
    let boundingBox = UIView()
    var originalImage: UIImage?
    let picutreView = UIView()
    let videoView = UIView()
    
    var frames:[UIImage] = []
    
    var timer = Timer()
        
    var topLeftDot: UIView? = nil
    var topRightDot: UIView? = nil
    var bottomLeftDot: UIView? = nil
    var bottomRightDot: UIView? = nil
    var looper = 0
    
    var timeCounter:Float64 = 0.00
    var timeCounter2:Int64 = 0
    var videoURL: URL? = nil
    
//    var imagePickerController = UIImagePickerController()
//    var videoURL : NSURL?
    
    var x1: CGFloat = 0
    var x2: CGFloat = 0
    var x3: CGFloat = 0
    var x4: CGFloat = 0
    var y1: CGFloat = 0
    var y2: CGFloat = 0
    var y3: CGFloat = 0
    var y4: CGFloat = 0
    
    let movingAverageSize = 100
    
    let lag = 90
    
    var movingAverage: [CGFloat] = []
    
    ////Two different models
    
//    let model: yolov5s_original_ane = {
//    do {
//        let config = MLModelConfiguration()
//        return try yolov5s_original_ane(configuration: config)
//    } catch {
//        print(error)
//        fatalError("Couldn't create yolov5s")
//    }
//    }()
    
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
        DispatchQueue.global(qos: .background).async { self.captureSession.startRunning() }
    }
    
    func stopSession() {
            if captureSession.isRunning {
                DispatchQueue.global(qos: .background).async { self.captureSession.stopRunning() }
            }
        }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        let rect = AVMakeRect(aspectRatio: CGSize(width: 16, height: 9), insideRect: view.bounds)
//        self.imageView.frame = rect
//        self.previewLayer.frame = rect
//        self.view.frame = rect
//        self.picutreView.frame = rect
        self.videoView.frame = rect
        self.picutreView.frame = rect
        let rect2 = AVMakeRect(aspectRatio: CGSize(width: 16, height: 9), insideRect: self.videoView.bounds)
        self.previewLayer.frame = rect2
        self.imageView.frame = rect2
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
        captureSession.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
        guard let captureDevice = AVCaptureDevice.default(.builtInUltraWideCamera,
                                                          for: AVMediaType.video, position: .back) else { return }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        view.addSubview(videoView)
        view.addSubview(picutreView)
        
        captureSession.addInput(input)

        imageView.frame = view.frame
//        self.view.addSubview(imageView)
        self.picutreView.addSubview(imageView)
//        self.picutreView.frame = view.frame
        
        
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
//        view.layer.addSublayer(previewLayer)
//        previewLayer.isHidden = true
        self.videoView.isHidden = true
        self.videoView.layer.addSublayer(previewLayer)
//        self.videoView.frame = view.frame
        

        boundingBox.layer.borderWidth = 4
        boundingBox.backgroundColor = .clear
        boundingBox.layer.borderColor = UIColor.blue.cgColor
        
        let viewTypeButton = UIButton()
        viewTypeButton.frame = CGRect(x: 75, y: 50, width: 50, height: 50)
        viewTypeButton.backgroundColor = UIColor.blue
        viewTypeButton.addTarget(self, action: #selector(buttonPressed),
                                    for: .touchDown)
        self.view.addSubview(viewTypeButton)
//        self.videoView.addSubview(viewTypeButton)
//        self.picutreView.addSubview(viewTypeButton)
        
        let selectVideoButton = UIButton()
        selectVideoButton.frame = CGRect(x: 75, y: 150, width: 50, height: 50)
        selectVideoButton.backgroundColor = UIColor.red
        selectVideoButton.addTarget(self, action: #selector(openVideoGallery),
                                    for: .touchDown)
        self.view.addSubview(selectVideoButton)
        
        let startLiveVideo = UIButton()
        startLiveVideo.frame = CGRect(x: 75, y: 250, width: 50, height: 50)
        startLiveVideo.backgroundColor = UIColor.green
        startLiveVideo.addTarget(self, action: #selector(startLiveVideoClicked),
                                    for: .touchDown)
        self.view.addSubview(startLiveVideo)
        
        let advanceFrame = UIButton()
        advanceFrame.frame = CGRect(x: 700, y: 150, width: 50, height: 50)
        advanceFrame.backgroundColor = UIColor.orange
        advanceFrame.addTarget(self, action: #selector(startFrameByFrame),
                                    for: .touchDown)
        self.view.addSubview(advanceFrame)
        
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        videoView.isUserInteractionEnabled = true
        videoView.addGestureRecognizer(tapGR)
        
        picutreView.isUserInteractionEnabled = true
        picutreView.addGestureRecognizer(tapGR)
        
        
    }
    
    @objc func startFrameByFrame(){
        self.timer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true, block: { _ in
            self.goToNextFrame()
            })
    }
    
    @objc func goToNextFrame(){
        guard let URL = self.videoURL else { return }
        
        DispatchQueue.main.async{
            let image = self.imageFromVideo(url: URL, fromTime: Float64(self.timeCounter))
//            self.imageView.image = image
            guard let image = image else{ return }
            if self.looper == 0 && self.bottomLeftDot == nil{
                self.imageView.image = image
            }else{
                self.runModelOnImage(image: image)
            }
        }
//        DispatchQueue.global(qos: .background).async {
//            let image = self.imageFromVideo(url: URL, fromTime: Float64(self.timeCounter))
//
//            DispatchQueue.main.async {
//                self.imageView.image = image
//            }
//        }
        print(timeCounter2)
        timeCounter2 += 20
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        let loc:CGPoint = sender.location(in: sender.view)
        let currentView = self.videoView.isHidden ? self.picutreView : self.videoView
        switch self.looper{
        case 0:
            looper += 1
            guard let topLeftDot = topLeftDot else {
                let dot = UIView(frame: CGRect(x: loc.x, y: loc.y, width: 10, height: 10))
                dot.backgroundColor = .blue
                self.topLeftDot = dot
                currentView.addSubview(dot) //add dot as subview to your main view
                return
            }
            topLeftDot.frame.origin.x = loc.x
            topLeftDot.frame.origin.y = loc.y
        case 1:
            looper += 1
            guard let topRightDot = topRightDot else {
                let dot = UIView(frame: CGRect(x: loc.x, y: loc.y, width: 10, height: 10))
                dot.backgroundColor = .green
                self.topRightDot = dot
                currentView.addSubview(dot) //add dot as subview to your main view
                return
            }
            topRightDot.frame.origin.x = loc.x
            topRightDot.frame.origin.y = loc.y
        case 2:
            looper += 1
            guard let bottomRightDot = bottomRightDot else {
                let dot = UIView(frame: CGRect(x: loc.x, y: loc.y, width: 10, height: 10))
                dot.backgroundColor = .red
                self.bottomRightDot = dot
                currentView.addSubview(dot) //add dot as subview to your main view
                return
            }
            bottomRightDot.frame.origin.x = loc.x
            bottomRightDot.frame.origin.y = loc.y
        case 3:
            self.looper = 0
            guard let bottomLeftDot = bottomLeftDot else {
                let dot = UIView(frame: CGRect(x: loc.x, y: loc.y, width: 10, height: 10))
                dot.backgroundColor = .orange
                self.bottomLeftDot = dot
                currentView.addSubview(dot) //add dot as subview to your main view
                calculateVals()
                return
            }
            bottomLeftDot.frame.origin.x = loc.x
            bottomLeftDot.frame.origin.y = loc.y
            calculateVals()
        default:
            self.looper = 0
        }
        
        
    }
    
    func calculateVals() {
        
        guard let topLeftDot = topLeftDot, let topRightDot = topRightDot,
                let bottomLeftDot = bottomLeftDot, let bottomRightDot = bottomRightDot else{ return }
//        let multFactor: CGFloat = 2160/videoView.frame.height
        let multFactor: CGFloat = 720/videoView.frame.height
        
        x1 = topLeftDot.frame.origin.x * multFactor
        y1 = topLeftDot.frame.origin.y * multFactor
        x2 = topRightDot.frame.origin.x * multFactor
        y2 = topRightDot.frame.origin.y * multFactor
        x3 = bottomRightDot.frame.origin.x * multFactor
        y3 = bottomRightDot.frame.origin.y * multFactor
        x4 = bottomLeftDot.frame.origin.x * multFactor
        y4 = bottomLeftDot.frame.origin.y * multFactor
    }
    
    @objc func openVideoGallery() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        picker.mediaTypes = ["public.movie"]
        picker.allowsEditing = false
        present(picker, animated: true, completion: nil)
    }
    
    @objc func startLiveVideoClicked() {
        viewIsLive()
    }
    
    func imagePickerController (_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
        {
            
            let videoNSURL = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
            
            print(videoNSURL ?? "")
            
            guard let URL = videoNSURL?.absoluteURL else { return }
            self.videoURL = URL
            DispatchQueue.main.async{
                let image = self.imageFromVideo(url: URL, fromTime: Float64(0))
                self.imageView.image = image
            }
            
             self.dismiss(animated: true, completion: nil)
        }
    
    @objc func buttonPressed() {
//        self.previewLayer.isHidden.toggle()
        self.videoView.isHidden.toggle()
        self.picutreView.isHidden.toggle()
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
    
    func imageFromVideo(url : URL, fromTime:Float64) -> UIImage? {
        let asset :AVAsset = AVAsset(url: url)
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter = CMTime.zero;
        assetImgGenerate.requestedTimeToleranceBefore = CMTime.zero;
//        let time        : CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale: 600)
        let time        : CMTime = CMTimeMake(value: self.timeCounter2, timescale: 600)
        let img: CGImage
        do {
            img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
        } catch let error {
            print("Error: \(error)")
            return nil
        }
        let frameImg    : UIImage = UIImage(cgImage: img)
        return frameImg
    }
    
    func runModelOnImage(image: UIImage){
        guard self.looper == 0, let _ = bottomLeftDot else { return }
        
        //save original image to be able to crop it later before the image gets masked to be fed into the model
        originalImage = image
        self.frames.insert(image, at: 0)
        
        guard let maskImage = drawOnImage(image) else { return }
   
        //Resizing image so that model works properly
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 640, height: 640))
        let testImage = renderer.image{(context) in
            maskImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 640, height: 640)))
        }
                    
        self.classify(image: testImage)
    }

    func captureOutput(_ output: AVCaptureOutput,
                           didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection) {
            guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                debugPrint("unable to get image from sample buffer")
                return
            }
        guard self.looper == 0, let _ = bottomLeftDot else { return }
            let ciimage = CIImage(cvImageBuffer: frame)
            let context = CIContext()
            if let cgImage = context.createCGImage(ciimage, from: ciimage.extent) {

                let uiImage = UIImage(cgImage: cgImage)
                
                //save original image to be able to crop it later before the image gets masked to be fed into the model
                originalImage = uiImage
                
                guard let maskImage = drawOnImage(uiImage) else { return }
           
                //Resizing image so that model works properly
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 640, height: 640))
                let testImage = renderer.image{(context) in
                    maskImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 640, height: 640)))
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
//        context.setFillColor(red: 0, green: 1, blue: 0, alpha: 1)

        // Draw a red line
        //penta = np.array([[245,345],[1055,345],[1220,435],[85,435]], np.int32)
        
        ////Arbitrary polygon points just to test if masking works properly
//        let x1 = 245 * 3
//        let x2 = 1055 * 3
//        let x3 = 1220 * 3
//        let x4 = 85 * 3
//        let y1 = 345 * 3
//        let y2 = 435 * 3
        
        context.setLineWidth(20)
        context.setStrokeColor(UIColor.black.cgColor)
        context.beginPath()
        context.move(to: CGPoint(x: 0, y: 0))
        context.addLine(to: CGPoint(x: image.size.width, y: 0))
        context.addLine(to: CGPoint(x: image.size.width, y: image.size.height))
        context.addLine(to: CGPoint(x: 0, y: image.size.height))
        context.move(to: CGPoint(x: x1, y: y1))
        context.addLine(to: CGPoint(x: x2, y: y2))
        context.addLine(to: CGPoint(x: x3, y: y3))
        context.addLine(to: CGPoint(x: x4, y: y4))
        context.addLine(to: CGPoint(x: x1, y: y1))
        context.closePath()
        context.setFillColor(UIColor.black.cgColor)
        
        context.fillPath(using: .evenOdd)
        context.strokePath()
        context.strokePath()
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
            
            let multiplyer = self.videoView.isHidden ? 1280 : 3240
            
                        
            people?.forEach{ it in
                if let person = it as? VNRecognizedObjectObservation{
                    totalX = totalX + (person.boundingBox.midX * (self.originalImage?.size.width ?? CGFloat(multiplyer)))
                }
            }
            
            if numOfPeople > 0 {
                
                print(Int(totalX))
                
                let avg:CGFloat = totalX/numOfPeople
                
                self.movingAverage.insert(avg, at: 0)
                if self.movingAverage.count > self.movingAverageSize {
                    _ = self.movingAverage.popLast()
                }
                
//                let mASum:CGFloat = self.movingAverage.reduce(0, +)
//
//                let xmid:CGFloat = mASum / CGFloat(self.movingAverage.count)
//
//                let w = (self.originalImage?.size.width ?? 1080) / 3
//                let h = (self.originalImage?.size.height ?? 720) / 3
//
//                let cropRect = CGRect(x: xmid - (w/2), y: h, width: w, height: h)
//
//                let croppedCGImage = self.originalImage?.cgImage?.cropping(to: cropRect)
//
//                guard let croppedCGImage = croppedCGImage, let originalImage = self.originalImage else { return }
//
//                let croppedImage = UIImage(
//                    cgImage: croppedCGImage,
//                    scale: originalImage.imageRendererFormat.scale,
//                    orientation: originalImage.imageOrientation
//                )
//
//                self.imageView.image = croppedImage
            }
            
            if self.frames.count > 90 {
                let image = self.frames.popLast()
                
                let mASum:CGFloat = self.movingAverage.reduce(0, +)
                
                let xmid:CGFloat = mASum / CGFloat(self.movingAverage.count)
                
                let w = (self.originalImage?.size.width ?? 1080) / 3
                let h = (self.originalImage?.size.height ?? 720) / 3
                                
                let cropRect = CGRect(x: xmid - (w/2), y: h, width: w, height: h)
                
                let croppedCGImage = image?.cgImage?.cropping(to: cropRect)
                
                guard let croppedCGImage = croppedCGImage, let originalImage = image else { return }
                
                let croppedImage = UIImage(
                    cgImage: croppedCGImage,
                    scale: originalImage.imageRendererFormat.scale,
                    orientation: originalImage.imageOrientation
                )
                
                self.imageView.image = croppedImage
            }
            
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

