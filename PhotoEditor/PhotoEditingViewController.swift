//
//  PhotoEditingViewController.swift
//  PhotoEditor
//
//  Created by Joses Solmaximo on 17/02/23.
//

import UIKit
import SwiftUI
import Photos
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision
import VisionKit
import AVFoundation

class PhotoEditingViewController: UIViewController, PHContentEditingController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    private let analyzer = ImageAnalyzer()
    private let interaction = ImageAnalysisInteraction()
    private let context = CIContext()
    
    private var input: PHContentEditingInput?
    private var editedImage: UIImage?
//    private var rects: [TextRect] = []
    private var editorMode: EditorMode = .auto
    private var undoStateManager = UndoStateManager.shared
    
    private var intensityHostingVC: UIHostingController<IntensityView>?
    
    private var toolbarHostingVC: UIHostingController<ToolbarView>?
    private var topToolbarHostingVC: UIHostingController<TopToolbarView>?
    private var toolbarViewModel = ToolbarViewModel()

    private var isFirstLoad = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.addInteraction(interaction)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
        
        imageView.isExclusiveTouch = false
        scrollView.delegate = self
        
        setupUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        undoStateManager.rects = []
        input = nil
        editedImage = nil
    }
    
    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        return true
    }
    
    func setupUI(){
        setupIntensityView()
        setupToolbarView()
        setupTopToolbarView()
    }
    
    func setupIntensityView(){
        intensityHostingVC = UIHostingController(rootView: IntensityView(vm: toolbarViewModel, delegate: self))
        
        guard let intensityHostingVC = intensityHostingVC else { return }
        
        let intensityView = intensityHostingVC.view!
        intensityView.translatesAutoresizingMaskIntoConstraints = false
        intensityView.backgroundColor = .clear
        
        addChild(intensityHostingVC)
        view.addSubview(intensityView)
        
        NSLayoutConstraint.activate([
            intensityView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            intensityView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
        ])
        
        intensityHostingVC.didMove(toParent: self)
    }
    
    func setupToolbarView(){
        toolbarHostingVC = UIHostingController(rootView: ToolbarView(vm: toolbarViewModel, delegate: self))
        
        guard let toolbarHostingVC = toolbarHostingVC else { return }
        
        let toolbarView = toolbarHostingVC.view!
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.backgroundColor = .clear
        
        addChild(toolbarHostingVC)
        view.addSubview(toolbarView)
        
        NSLayoutConstraint.activate([
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            toolbarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
        
        toolbarHostingVC.didMove(toParent: self)
    }
    
    func setupTopToolbarView(){
        topToolbarHostingVC = UIHostingController(rootView: TopToolbarView(vm: toolbarViewModel, delegate: self))
        
        guard let topToolbarHostingVC = topToolbarHostingVC else { return }
        
        let topToolbarView = topToolbarHostingVC.view!
        topToolbarView.translatesAutoresizingMaskIntoConstraints = false
        topToolbarView.backgroundColor = .clear
        
        addChild(topToolbarHostingVC)
        view.addSubview(topToolbarView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        NSLayoutConstraint.activate([
            topToolbarView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            topToolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
        ])
        
        topToolbarHostingVC.didMove(toParent: self)
    }
    
    @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let tapLocation = gestureRecognizer.location(in: imageView)
        
        let oldRects = self.undoStateManager.rects
        var newRects = self.undoStateManager.rects
        
        let avRect = AVMakeRect(aspectRatio: imageView.image!.size, insideRect: imageView.bounds)
        
        if toolbarViewModel.detectionMode == .manual && toolbarViewModel.manualMode != .censor {
            if toolbarViewModel.manualMode == .draw {
                for (index, textRect) in newRects.enumerated() {
                    let box = textRect.rect.convert(to: avRect)
                    if box.contains(tapLocation) {
                        newRects[index].visible = false
                        movingRect = textRect
                        break
                    }
                    
                    movingRect = nil
                }
            }
        } else {
            for (index, textRect) in newRects.enumerated() {
                let box = textRect.rect.convert(to: avRect)
                
                if box.contains(tapLocation) && (textRect.textRecognizerMode == toolbarViewModel.toolbarState.textRecognizerMode || textRect.visible || textRect.detectionMode == .manual) {
                    if textRect.censorMode != toolbarViewModel.censorMode {
                        newRects[index].visible = true
                    } else {
                        newRects[index].visible.toggle()
                    }
    
                    newRects[index].censorMode = toolbarViewModel.censorMode
    
                    if toolbarViewModel.censorMode == .bar {
                        newRects[index].color = toolbarViewModel.barColor
                    } else if toolbarViewModel.censorMode == .highlight {
                        newRects[index].color = toolbarViewModel.highlightColor
                    } else if toolbarViewModel.censorMode == .underline {
                        newRects[index].color = toolbarViewModel.underlineColor
                    }
                }
            }
        }
        
        undoStateManager.modifyRects(newRects)
        
        drawRectangles(input: input)
    }
    
    var startPoint: CGPoint?
    var movingRect: TextRect?
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer){
        let location = sender.location(in: imageView)
        let avRect = AVMakeRect(aspectRatio: imageView.image!.size, insideRect: imageView.bounds)
        
        guard toolbarViewModel.detectionMode == .manual else { return }
        
        switch sender.state {
        case .began:
            startPoint = location
        case .changed:
            if let rect = movingRect {
                moveRect(rect: rect, translation: sender.translation(in: imageView))
            } else {
                for view in imageView.subviews {
                    if view.tag == 2 {
                        view.removeFromSuperview()
                    }
                }

                let size = CGSize(width: (location.x - startPoint!.x), height: (location.y - startPoint!.y))
                let view = UIView(frame: CGRect(origin: startPoint!, size: size))
                
                if toolbarViewModel.manualMode == .erase {
                    view.layer.backgroundColor = UIColor.red.withAlphaComponent(0.3).cgColor
                } else {
                    view.layer.borderColor = UIColor.black.cgColor
                    view.layer.borderWidth = 2
                }
                
                view.tag = 2

                imageView.addSubview(view)
            }
        case .ended:
            if let rect = movingRect {
                movingRect = undoStateManager.rects.first(where: { $0.id == rect.id })
            } else {
                let oldRects = self.undoStateManager.rects
                var newRects = self.undoStateManager.rects
                
                let size = CGSize(width: (location.x - startPoint!.x), height: (location.y - startPoint!.y))
                let rect = CGRect(origin: startPoint!, size: size)

                let correctedRect = CGRect(origin: .init(x: rect.minX, y: rect.minY), size: .init(width: rect.maxX - rect.minX, height: rect.maxY - rect.minY))

                if toolbarViewModel.manualMode != .erase {
                    newRects.append(.init(rect: correctedRect.revert(to: avRect), textRecognizerMode: .perLine, censorMode: .bar, detectionMode: .manual, color: .black, visible: false))
                }

                for view in imageView.subviews {
                    if view.tag == 2 {
                        view.removeFromSuperview()
                    }
                }
                
                if toolbarViewModel.manualMode == .erase {
                    for rect in oldRects {
                        let box = rect.rect.convert(to: avRect)
                        
                        let topLeft = CGPoint(x: box.minX, y: box.minY)
                        let topRight = CGPoint(x: box.maxX, y: box.minY)
                        
                        let topCenter = CGPoint(x: box.midX, y: box.minY)
                        let bottomCenter = CGPoint(x: box.midX, y: box.maxY)
                        
                        let centerLeft = CGPoint(x: box.minX, y: box.midY)
                        let centerRight = CGPoint(x: box.maxX, y: box.midY)
                        
                        let bottomLeft = CGPoint(x: box.minX, y: box.maxY)
                        let bottomRight = CGPoint(x: box.maxX, y: box.maxY)
                        
                        for point in [topLeft, topRight, topCenter, bottomCenter, centerLeft, centerRight, bottomLeft, bottomRight] {
                            if let index = newRects.firstIndex(where: { $0.id == rect.id }), correctedRect.contains(point){
                                newRects.remove(at: index)
                                break
                            }
                        }
                    }
                }
                
                self.undoStateManager.modifyRects(newRects)
                
                if toolbarViewModel.manualMode == .erase {
                    drawRectangles(input: self.input)
                }
                
                drawRectanglesOverlay()
            }
        default:
            break
        }
    }
    
//    func undoImage(oldRects: [TextRect], newRects: [TextRect]){
//        toolbarViewModel.undoCount += 1
//        toolbarViewModel.undoManager.registerUndo(withTarget: self) { target in
//            target.redoImage(oldRects: oldRects, newRects: newRects)
//            target.undoStateManager.rects = oldRects
//            target.drawRectangles(input: target.input)
//            target.toolbarViewModel.redoCount += 1
//        }
//    }
//
//    func redoImage(oldRects: [TextRect], newRects: [TextRect]){
//        toolbarViewModel.undoCount -= 1
//        toolbarViewModel.undoManager.registerUndo(withTarget: self) { target in
//            target.undoImage(oldRects: oldRects, newRects: newRects)
//            target.undoStateManager.rects = newRects
//            target.drawRectangles(input: target.input)
//
//            target.toolbarViewModel.redoCount -= 1
//        }
//    }
    
    func moveRect(rect: TextRect, translation: CGPoint){
        let avRect = AVMakeRect(aspectRatio: imageView.image!.size, insideRect: imageView.bounds)
        var modifiedRect = rect.rect.convert(to: avRect)
        
        let bottomLeftBox = CGRect(x: modifiedRect.maxX - 0, y: modifiedRect.maxY - 0, width: 30, height: 30)
        let topRightBox = CGRect(x: modifiedRect.minX - 30, y: modifiedRect.minY - 30, width: 30, height: 30)
        
        if let startPoint = startPoint, bottomLeftBox.contains(startPoint) {
            modifiedRect.size.width += translation.x
            modifiedRect.size.height += translation.y
        } else if let startPoint = startPoint, topRightBox.contains(startPoint) {
            modifiedRect.origin.x += translation.x
            modifiedRect.origin.y += translation.y
            modifiedRect.size.width -= translation.x
            modifiedRect.size.height -= translation.y
        } else {
            modifiedRect.origin.x += translation.x
            modifiedRect.origin.y += translation.y
        }
        
        if let index = undoStateManager.rects.firstIndex(where: {$0.id == rect.id}){
            
            undoStateManager.rects[index].rect = modifiedRect.revert(to: avRect)
            drawRectanglesOverlay()
            
            if undoStateManager.rects[index].visible {
                undoStateManager.rects[index].visible = false
                
                drawRectangles(input: self.input)
            }
        }
    }
    
    func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: UIImage) {
        input = contentEditingInput
        imageView.image = contentEditingInput.displaySizeImage
        interaction.preferredInteractionTypes = []
        
        if let path = contentEditingInput.fullSizeImageURL?.path(),
           let image = UIImage(contentsOfFile: path)
        {
            let config = ImageAnalyzer.Configuration([.text, .machineReadableCode])
            Task {
                do {
                    withAnimation {
                        toolbarViewModel.isRecognizingText = true
                    }
                    
                    let analysis = try await analyzer.analyze(image, configuration: config)
                    
                    interaction.analysis = analysis
                    interaction.preferredInteractionTypes = .automatic
                    interaction.isSupplementaryInterfaceHidden = true
                    
                    recognizeText(input: self.input)
                } catch {
                    
                }
            }
        }
    }
    
    func finishContentEditing(completionHandler: @escaping ((PHContentEditingOutput?) -> Void)) {
        
        if input == nil {
            self.cancelContentEditing()
            return
        }
        
        DispatchQueue.global().async() {
            let contentEditingOutput = PHContentEditingOutput(contentEditingInput: self.input!)
            let archiveData = try? NSKeyedArchiver.archivedData(withRootObject: "Blackout", requiringSecureCoding: false)
            let identifier = "com.josessolmaximo.Blackout.PhotoEditor"
            let adjustmentData = PHAdjustmentData(formatIdentifier: identifier, formatVersion: "1.0.0", data: archiveData!)
            
            contentEditingOutput.adjustmentData = adjustmentData
            
            let jpegData = self.editedImage!.jpegData(compressionQuality: 1.0)!
            
            try? jpegData.write(to: contentEditingOutput.renderedContentURL, options: .atomic)
            
            completionHandler(contentEditingOutput)
            
            self.undoStateManager.rects = []
        }
    }
    
    var shouldShowCancelConfirmation: Bool {
        return false
    }
    
    func cancelContentEditing() {
        
    }
}

extension PhotoEditingViewController {
    func recognizeText(input: PHContentEditingInput?) {
        guard let path = input?.fullSizeImageURL?.path(),
              let image = UIImage(contentsOfFile: path),
              let cgImage = image.cgImage
        else {
            return
        }
        
        withAnimation {
            toolbarViewModel.isRecognizingText = true
        }
        
        let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(rawValue: UInt32((input?.fullSizeImageOrientation)!)) ?? .up)
        
        let request = VNRecognizeTextRequest { request, error in
            
            guard let results = request.results as? [VNRecognizedTextObservation],
                  error == nil
            else {
                return
            }
            
            let oldRects = self.undoStateManager.rects
            var newRects = self.undoStateManager.rects
            
            if !self.isFirstLoad {
                newRects.removeAll(where: { !$0.visible && $0.detectionMode == .auto})
            }
            
            results.forEach { result in
                if let text = result.topCandidates(1).first {
                    if self.toolbarViewModel.toolbarState.textRecognizerMode == .perLine {
                        if let range = text.string.range(of: text.string),
                           let box = try? text.boundingBox(for: range)?.boundingBox {
                            if !newRects.contains(where: { $0.rect == box }){
                                newRects.append(.init(rect: box, textRecognizerMode: self.toolbarViewModel.toolbarState.textRecognizerMode, censorMode: self.toolbarViewModel.censorMode, color: self.toolbarViewModel.barColor, visible: false))
                            }
                        }
                    } else if self.toolbarViewModel.toolbarState.textRecognizerMode == .perWord {
                        let words = text.string.split(separator: " ")
                        for word in words {
                            if let range = text.string.range(of: "\(word)"),
                               let box = try? text.boundingBox(for: range)?.boundingBox {
                                if !newRects.contains(where: { $0.rect == box}){
                                    newRects.append(.init(rect: box, textRecognizerMode: self.toolbarViewModel.toolbarState.textRecognizerMode, censorMode: self.toolbarViewModel.censorMode, color: self.toolbarViewModel.barColor, visible: false))
                                }
                            }
                        }
                    }
                }
            }
            
            self.undoStateManager.modifyRects(newRects)
//            self.undoStateManager.rects = newRects
            self.drawRectangles(input: input)
            
            if self.isFirstLoad {
                self.isFirstLoad = false
            }
            
            DispatchQueue.main.async {
                withAnimation {
                    self.toolbarViewModel.isRecognizingText = false
                }
            }
        }
        
        request.recognitionLevel = .accurate
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform([request])
            } catch {
                return
            }
        }
    }
    
    func drawRectangles(input: PHContentEditingInput?){
        guard let path = input?.fullSizeImageURL?.path(),
              let image = UIImage(contentsOfFile: path),
              let cgImage = image.cgImage
        else { return }
        
        let rects = self.undoStateManager.rects
        
        var size: CGSize {
            if image.size.width == CGFloat(cgImage.height) {
                return CGSize(width: cgImage.height, height: cgImage.width)
            } else {
                return CGSize(width: cgImage.width, height: cgImage.height)
            }
        }
        
        let bounds = CGRect(origin: .zero, size: size)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let ciImage = CIImage(cgImage: cgImage)
        
        var blurredImage: CGImage?
        var pixelatedImage: CGImage?
        var pixelColors: [UUID: UIColor] = [:]
        
        if rects.contains(where: {$0.censorMode == .blur}) {
            let blurFilter = CIFilter.gaussianBlur()
            blurFilter.radius = Float(toolbarViewModel.toolbarState.blurRadius)
            blurFilter.inputImage = ciImage.clampedToExtent()
            
            let filterOutput = blurFilter.outputImage
            
            guard let filterOutput = filterOutput,
                  let cgOutput = context.createCGImage(filterOutput, from: ciImage.extent)
            else { return }
            
            blurredImage = cgOutput
        }
        
        if rects.contains(where: {$0.censorMode == .pixel}) {
            let pixelFilter = CIFilter.pixellate()
            pixelFilter.scale = Float(toolbarViewModel.toolbarState.pixelScale)
            pixelFilter.inputImage = ciImage.clampedToExtent()
            
            let filterOutput = pixelFilter.outputImage
            
            guard let filterOutput = filterOutput,
                  let cgOutput = context.createCGImage(filterOutput, from: ciImage.extent)
            else { return }
            
            pixelatedImage = cgOutput
        }
        
        if rects.contains(where: {$0.censorMode == .blend}){
            pixelColors = cgImage.getPixelColors(rects: rects.filter({$0.censorMode == .blend}), imageRect: bounds) ?? [:]
        }
        
        let final = UIGraphicsImageRenderer(bounds: bounds, format: format).image { _ in
            image.draw(in: bounds)
            
            for rect in rects {
                if let _ = rects.firstIndex(where: {$0.id == rect.id}) {
                    let box = rect.rect.convert(to: bounds)
                    
                    if rect.visible {
                        let roundedBox = CGRect(
                            x: (box.origin.x - 1.5).rounded(),
                            y: (box.origin.y - 1.5).rounded(),
                            width: (box.width + 3).rounded(),
                            height: (box.height + 3).rounded())
                        
                        if rect.censorMode == .blur {
                            guard let blurredImage = blurredImage,
                                  let croppedImage = blurredImage.cropping(to: roundedBox)
                            else { continue }
                            
                            let blurredUIImage = UIImage(cgImage: croppedImage)
                            
                            blurredUIImage.draw(in: roundedBox)
                        } else if rect.censorMode == .pixel {
                            guard let pixelatedImage = pixelatedImage,
                                  let croppedImage = pixelatedImage.cropping(to: roundedBox)
                            else { continue }
                            
                            
                            let pixelatedUIImage = UIImage(cgImage: croppedImage)
                            
                            pixelatedUIImage.draw(in: roundedBox)
                        } else if rect.censorMode == .bar || rect.censorMode == .highlight {
                            UIColor(rect.color).setFill()
                            let path = UIBezierPath(rect: roundedBox)
                            path.fill()
                        } else if rect.censorMode == .blend {
                            let path = UIBezierPath(rect: roundedBox)
                            pixelColors[rect.id]!.setFill()
                            path.fill()
                        } else if rect.censorMode == .underline {
                            let underlineBox = CGRect(x: box.origin.x, y: box.maxY + 5, width: box.width, height: 5)
                            UIColor(rect.color).setFill()
                            let path = UIBezierPath(rect: underlineBox)
                            path.fill()
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.async { [self] in
            self.imageView.image = final
            
            drawRectanglesOverlay()
        }
        
        self.editedImage = final
    }
    
    func drawRectanglesOverlay(){
        
        imageView.subviews.forEach { view in
            if view.tag == 1 {
                view.removeFromSuperview()
            }
        }
        
        if toolbarViewModel.toolbarState.isOverlayVisible {
            let avRect = AVMakeRect(aspectRatio: imageView.image!.size, insideRect: imageView.bounds)
            
            for rect in undoStateManager.rects {
                let box = rect.rect.convert(to: avRect)
                let convertedBox = CGRect(x: box.origin.x, y: box.origin.y, width: box.width, height: box.height)
                
                let view = UIView(frame: convertedBox)
                view.layer.borderColor = UIColor.black.cgColor
                view.layer.borderWidth = 1.5
                view.tag = 1
                
                let center = CGPoint(x: box.midX, y: box.midY)
                
//                if rect.detectionMode == .manual || (interaction.analysisHasText(at: center) && rect.textRecognizerMode == toolbarViewModel.textRecognizerMode) {
//                    self.imageView.addSubview(view)
//                }
                
                if rect.detectionMode == .manual || interaction.analysisHasText(at: center) {
                    self.imageView.addSubview(view)
                }
                
                if movingRect?.id == rect.id && toolbarViewModel.manualMode == .draw {
                    let bottomLeft = UIImageView(frame: CGRect(x: convertedBox.maxX, y: convertedBox.maxY, width: 10, height: 10))
                    bottomLeft.image = UIImage(systemName: "arrow.down.right", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
                    bottomLeft.tintColor = .black
                    bottomLeft.tag = 1
                    
                    imageView.addSubview(bottomLeft)
                    
                    let topRight = UIImageView(frame: CGRect(x: convertedBox.minX - 10, y: convertedBox.minY - 10, width: 10, height: 10))
                    topRight.image = UIImage(systemName: "arrow.up.left", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
                    topRight.tintColor = .black
                    topRight.tag = 1
                    
                    imageView.addSubview(topRight)
                }
            }
        }
    }
}

extension PhotoEditingViewController: IntensityViewDelegate {
    func intensityChanged(intensityView: IntensityView) {
        drawRectangles(input: input)
    }
}

extension PhotoEditingViewController: ToolbarViewDelegate {
    func textRecognizerModeChanged(textRecognizerMode: TextRecognizerMode) {
        recognizeText(input: input)
    }
    
    func censorModeChanged(censorMode: CensorMode) {
        if censorMode == .blur {
            intensityHostingVC?.view.isHidden = false
        } else if censorMode == .pixel {
            intensityHostingVC?.view.isHidden = false
        } else {
            intensityHostingVC?.view.isHidden = false
        }
    }
    
    func redrawRectangle() {
        drawRectangles(input: input)
    }
}

extension PhotoEditingViewController: TopToolbarViewDelegate {
    func isOverlayVisibleChanged() {
        drawRectanglesOverlay()
    }
}

extension PhotoEditingViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
