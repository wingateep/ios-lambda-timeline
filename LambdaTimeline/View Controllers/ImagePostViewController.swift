//
//  ImagePostViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

@available(iOS 13.0, *)
class ImagePostViewController: ShiftableViewController {
    
     override func viewDidLoad() {
          super.viewDidLoad()
          setImageViewHeight(with: 1.0)
          
          updateViews()
      }
      
      private var originalImage: UIImage? {
          didSet {
              guard let originalImage = UIImage(data: imageData!) else { return }
              
              var scaledSize = imageView.bounds.size
              let scale = UIScreen.main.scale
              scaledSize = CGSize(width: scaledSize.width * scale, height: scaledSize.height * scale)
              scaledImage = originalImage.imageByScaling(toSize: scaledSize)
          }
      }
      
      private var scaledImage: UIImage? {
          didSet {
              updateViews()
          }
      }
      
      private var context = CIContext(options: nil)
      private var vibranceFilter = CIFilter.vibrance()
    
    // MARK: IBOutlets
    
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var contrastSlider: UISlider!
    @IBOutlet weak var saturationSlider: UISlider!
    @IBOutlet weak var blurRadiusSlider: UISlider!
    @IBOutlet weak var vibranceSlider: UISlider!
    
    func updateViews() {
          
          guard let imageData = imageData,
              let image = UIImage(data: imageData) else {
                  title = "New Post"

                  return
          }
          
          title = post?.title
          
          setImageViewHeight(with: image.ratio)
          
          imageView.image = image
          
          chooseImageButton.setTitle("", for: [])
      }
    
    private func presentImagePickerController() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            presentInformationalAlertController(title: "Error", message: "The photo library is unavailable")
            return
        }
        
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        
        imagePicker.sourceType = .photoLibrary

        present(imagePicker, animated: true, completion: nil)
    }
    
        // MARK: Slider events
        
        @IBAction func brightnessChanged(_ sender: UISlider) {
            updateViews()
        }
        
        @IBAction func contrastChanged(_ sender: Any) {
            updateViews()
        }
        
        @IBAction func saturationChanged(_ sender: Any) {
            updateViews()
        }
    
        @IBAction func blurRadiusChanged(_ sender: Any) {
           updateViews()
        }
    
        @IBAction func vibranceChanged(_ sender: Any) {
        updateViews()
        }
    
    // MARK: - Private Methods
    
    private func filterImage(_ image: UIImage) -> UIImage? {
            
            guard let cgImage = image.cgImage else { return nil }
            
            let ciImage = CIImage(cgImage: cgImage)
            
            let filter = CIFilter.colorControls()
            
            filter.inputImage = ciImage
            filter.brightness = brightnessSlider.value
            filter.contrast = contrastSlider.value
            filter.saturation = saturationSlider.value
            
            guard let outputCIImage = filter.outputImage else { return nil }
            
            guard let outputCGImage = context.createCGImage(outputCIImage,
                                                            from: CGRect(origin: .zero, size: image.size)) else {
                                                                return nil
            }
            return UIImage(cgImage: outputCGImage)
        }

    @IBAction func createPost(_ sender: Any) {
        
        view.endEditing(true)
        
        guard let imageData = imageView.image?.jpegData(compressionQuality: 0.1),
            let title = titleTextField.text, title != "" else {
            presentInformationalAlertController(title: "Uh-oh", message: "Make sure that you add a photo and a caption before posting.")
            return
        }
        
        postController.createPost(with: title, ofType: .image, mediaData: imageData, ratio: imageView.image?.ratio) { (success) in
            guard success else {
                DispatchQueue.main.async {
                    self.presentInformationalAlertController(title: "Error", message: "Unable to create post. Try again.")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func chooseImage(_ sender: Any) {
        
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .authorized:
            presentImagePickerController()
        case .notDetermined:
            
            PHPhotoLibrary.requestAuthorization { (status) in
                
                guard status == .authorized else {
                    NSLog("User did not authorize access to the photo library")
                    self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
                    return
                }
                
                self.presentImagePickerController()
            }
            
        case .denied:
            self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
        case .restricted:
            self.presentInformationalAlertController(title: "Error", message: "Unable to access the photo library. Your device's restrictions do not allow access.")
            
        @unknown default:
            print("FatalError")
        }
        presentImagePickerController()
    }
    
    func setImageViewHeight(with aspectRatio: CGFloat) {
        
        imageHeightConstraint.constant = imageView.frame.size.width * aspectRatio
        
        view.layoutSubviews()
    }
    
    private func colorControlFilter(_ image: CGImage) -> CIImage? {
        let ciImage = CIImage(cgImage: image)
        let colorControlsFilter = CIFilter.colorControls()
        colorControlsFilter.inputImage = ciImage
        colorControlsFilter.brightness = brightnessSlider.value
        colorControlsFilter.contrast = contrastSlider.value
        colorControlsFilter.saturation = saturationSlider.value
        
        guard let outputCIImage = colorControlsFilter.outputImage else { return nil }
        return outputCIImage
    }
    
    func blurImage(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        
        let filter = CIFilter.gaussianBlur()
        
        filter.inputImage = ciImage
        filter.radius = blurRadiusSlider.value

        guard let outputCIImage = filter.outputImage else { return nil }
        guard let outputCGImage = context.createCGImage(outputCIImage, from: CGRect(origin: .zero, size: image.size)) else { return nil }
        
        return UIImage(cgImage: outputCGImage)
    }
    
     var postController: PostController!
     var post: Post?
     var imageData: Data?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var chooseImageButton: UIButton!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postButton: UIBarButtonItem!
}

@available(iOS 13.0, *)
extension ImagePostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        chooseImageButton.setTitle("", for: [])
        
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
        imageView.image = image
        
        setImageViewHeight(with: image.ratio)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
