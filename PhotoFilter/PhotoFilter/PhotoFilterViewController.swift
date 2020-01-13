import UIKit
import CoreImage
import Photos

class PhotoFilterViewController: UIViewController {
    
    var originalImage: UIImage? {
        didSet {
            guard let originalImage = originalImage else { return }
            // Height and width
            var scaledSize = imageView.bounds.size
            // 1x, 2x, or 3x
            let scale = UIScreen.main.scale
            scaledSize = CGSize(width: scaledSize.width * scale, height: scaledSize.height * scale)
            print("Size: \(scaledSize)")
            scaledImage = originalImage.imageByScaling(toSize: scaledSize)
        }
    }
    var scaledImage: UIImage? {
        didSet {
            updateImage()
        }
    }
    
    
    let context = CIContext(options: nil)
    let filter = CIFilter(name: "CIColorControls")!
    
    
    
    @IBOutlet var brightnessSlider: UISlider!
    @IBOutlet var contrastSlider: UISlider!
    @IBOutlet var saturationSlider: UISlider!
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originalImage = imageView.image
        
    }
    
    private func filterImage(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        // Set up the filter
        // k = constant
        filter.setValue(ciImage, forKey: kCIInputImageKey) // "inputImage")
        filter.setValue(brightnessSlider.value, forKey: kCIInputBrightnessKey)
        filter.setValue(contrastSlider.value, forKey: kCIInputContrastKey)
        filter.setValue(saturationSlider.value, forKey: kCIInputSaturationKey)
        
        // Get Output
        guard let outputCIImage = filter.outputImage else { return image }
        
        // TODO: render the image
        guard let outputCGImage = context.createCGImage(outputCIImage, from: CGRect(origin: CGPoint.zero, size: image.size)) else { return image }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    // MARK: Actions
    
    @IBAction func choosePhotoButtonPressed(_ sender: Any) {
        // TODO: show the photo picker so we can choose on-device photos
        // UIImagePickerController + Delegate
        presentImagePickerController()
    }
    
    private func presentImagePickerController() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("The photo library is not available")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
        
        
    }

    @IBAction func savePhotoButtonPressed(_ sender: UIButton) {
        // TODO: Save to photo library (full size image)

        guard let originalImage = originalImage else { return }
        
        let processedImage = filterImage(originalImage.flattened)
        
        PHPhotoLibrary.requestAuthorization { (status) in
            
            guard status == .authorized else { return }
            // Let the library know we are going to make changes
            
            PHPhotoLibrary.shared().performChanges({
                // Make a new photo creation request
                
                PHAssetCreationRequest.creationRequestForAsset(from: processedImage) }, completionHandler: { (success, error) in
                if let error = error {
                    NSLog("Error saving photo: \(error)")
                    return
                }
                DispatchQueue.main.async {
                    print("Saved image!")
                }
            })
        }
    }
    
    
    // MARK: Slider events
    
    @IBAction func brightnessChanged(_ sender: UISlider) {
        updateImage()
    }
    
    @IBAction func contrastChanged(_ sender: Any) {
        updateImage()
        
    }
    
    @IBAction func saturationChanged(_ sender: Any) {
        updateImage()
    }
    
    // DRY: Don't Repeat Yoursef
    private func updateImage() {
        if let scaledImage = scaledImage {
            imageView.image = filterImage(scaledImage)
        } else {
            imageView.image = nil
        }
    }
}

extension PhotoFilterViewController: UIImagePickerControllerDelegate  {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // First use the edited (if it exists), otherwise usethe original
        if let image = info[.editedImage] as? UIImage { // .originalImage
            originalImage = image
        } else if let image = info[.originalImage] as? UIImage {
            originalImage = image
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


extension PhotoFilterViewController: UINavigationControllerDelegate {
}
