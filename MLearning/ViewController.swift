//
//  ViewController.swift
//  MLearning
//
//  Created by CICE on 16/11/18.
//  Copyright © 2018 CICE. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var objectLabel: UILabel!
    
    var modelo: Inceptionv3!
    
    override func viewWillAppear(_ animated: Bool) {
        modelo = Inceptionv3()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func camara(_ sender: Any) {
        if !UIImagePickerController.isSourceTypeAvailable(.camera){
            return
        }
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        
        present(cameraPicker, animated: true)
        
    }
    
    @IBAction func abrirLibreria(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        objectLabel.text = "Analizando Imagen"
        
        guard let imagen = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        
        imagen.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299), blendMode: CGBlendMode.normal, alpha: 1.0)
        let nuevaImagen = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let atributos = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(nuevaImagen.size.width), Int(nuevaImagen.size.height), kCVPixelFormatType_32ARGB, atributos, &pixelBuffer)
        
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let contexto = CGContext(data: pixelData, width: Int(nuevaImagen.size.width), height: Int(nuevaImagen.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        contexto?.translateBy(x: 0, y: nuevaImagen.size.height)
        contexto?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(contexto!)
        
        nuevaImagen.draw(in: CGRect(x: 0, y: 0, width: nuevaImagen.size.width, height: nuevaImagen.size.height), blendMode: CGBlendMode.normal, alpha: 1.0)
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        imageView.image = nuevaImagen
        
        guard let prediccion = try? modelo.prediction(image: pixelBuffer!) else{return}
        objectLabel.text = "Esto se parece a \(prediccion.classLabel)"
        
    }

}

