//
//  HomeView.swift
//  Blackout
//
//  Created by Joses Solmaximo on 18/02/23.
//

import SwiftUI
import PhotosUI

struct HomeView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    var body: some View {
        ZStack {
            
            VStack {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()) {
                        Text("Select a photo")
                    }
                
                if let selectedImageData,
                   let uiImage = UIImage(data: selectedImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                   undoRedo
                    
                    Rectangle()
                        .frame(width: 1, height: 20)
                        .foregroundColor(.white)
                    
                    
                    textSelection
                    
                    Rectangle()
                        .frame(width: 1, height: 20)
                        .foregroundColor(.white)
                    
                    editingOptions
                    
                    Rectangle()
                        .frame(width: 1, height: 20)
                        .foregroundColor(.white)
                    
                    ColorPicker("", selection: .constant(.black), supportsOpacity: true)
                        .labelsHidden()
                }
                .padding(.horizontal)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(.black)
                .foregroundColor(.white)
            }
            
            VStack {
                
                Spacer()
                
                HStack {
                    
                    Spacer()
                    
                    VStack {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 17, weight: .semibold))
                        Text("10")
                            .foregroundColor(.black)
                            .fontWeight(.semibold)
                            .padding(.vertical, 10)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(width: 35, height: 80)
                    .background(
                        Color(uiColor: .systemGray5)
                            .cornerRadius(15)
                            .opacity(0.8)
                    )
                    
                    Spacer()
                        .frame(width: 20)
                }
                
                Spacer()
                    .frame(height: 70)
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

extension HomeView {
    
    var undoRedo: some View {
        HStack(spacing: 12.5) {
            VStack(spacing: 5) {
                Image(systemName: "arrow.uturn.backward")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.top, 20)
            
            VStack(spacing: 5) {
                Image(systemName: "arrow.uturn.forward")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.top, 20)
        }
    }
    
    var textSelection: some View {
        HStack(spacing: 12.5){
            VStack(spacing: 5) {
                Image(systemName: "wand.and.stars")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("Auto")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.top, 20)
            
            VStack(spacing: 5) {
                Image(systemName: "textformat.size")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("Mode")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.top, 20)
        }
    }
    
    var editingOptions: some View {
        HStack(spacing: 12.5){
            VStack(spacing: 5) {
                Rectangle()
                    .frame(width: 20, height: 5)
                    .padding(.vertical, 7.5)
                Text("Bar")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.top, 20)
            
            VStack(spacing: 5) {
                Image(systemName: "drop")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("Blur")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.top, 20)
            
            VStack(spacing: 5) {
                Image(systemName: "checkerboard.rectangle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("Pixel")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.top, 20)
            
            VStack(spacing: 5) {
                Image(systemName: "eraser")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("Blend")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.top, 20)
        }
    }
}
