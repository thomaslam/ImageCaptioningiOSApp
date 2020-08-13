//
//  ContentView.swift
//  ImageCaptioningiOSApp
//
//  Created by Thomas Lam on 8/11/20.
//  Copyright © 2020 Thomas Lam. All rights reserved.
//

import SwiftUI
import CoreML
import Vision

struct ContentView: View {
    @State private var isShowPhotoLibrary = false
    @State private var image = UIImage()
    
    private var classificationRequest: VNCoreMLRequest = {
      do {
        let model = try VNCoreMLModel(for: SqueezeNet().model)
        let request = VNCoreMLRequest(model: model) { request, _ in
            if let classifications =
              request.results as? [VNClassificationObservation] {
              print("Classification results: \(classifications)")
            }
        }
        request.imageCropAndScaleOption = .centerCrop
        return request
      } catch {
        fatalError("Failed to load Vision ML model: \(error)")
      }
    }()

    
    var body: some View {
        VStack {
            Image(uiImage: self.image)
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity)
                .edgesIgnoringSafeArea(.all)
            
            Button(action: {
                self.classifyImage(self.$image.wrappedValue)
            }){
                Text("Generate caption")
            }
            
            Button(action: {
                self.isShowPhotoLibrary = true
            }) {
                HStack {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                    
                    Text("Photo library")
                        .font(.headline)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(20)
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $isShowPhotoLibrary) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: self.$image)
        }
    }
    
    private func classifyImage(_ image: UIImage) {
      // 1
      guard let orientation = CGImagePropertyOrientation(
        rawValue: UInt32(image.imageOrientation.rawValue)) else {
        return
      }
      guard let ciImage = CIImage(image: image) else {
        fatalError("Unable to create \(CIImage.self) from \(image).")
      }
      // 2
      DispatchQueue.global(qos: .userInitiated).async {
        let handler =
          VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
        do {
            try handler.perform([self.classificationRequest])
        } catch {
          print("Failed to perform classification.\n\(error.localizedDescription)")
        }
      }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
