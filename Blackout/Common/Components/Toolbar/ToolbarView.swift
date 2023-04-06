//
//  ToolbarView.swift
//  Blackout
//
//  Created by Joses Solmaximo on 24/02/23.
//

import SwiftUI

struct ToolbarView: View {
    @StateObject var vm: ToolbarViewModel
    
    let delegate: ToolbarViewDelegate?
    
    init(vm: ToolbarViewModel, delegate: ToolbarViewDelegate?) {
        self._vm = StateObject(wrappedValue: vm)
        self.delegate = delegate
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                undoRedo
                
                Rectangle()
                    .frame(width: 1, height: 20)
                    .offset(y: -7.5)
                    .foregroundColor(.white)
                
                textSelection
                
                Rectangle()
                    .frame(width: 1, height: 20)
                    .offset(y: -7.5)
                    .foregroundColor(.white)
                
                editingOptions
            }
            .padding(.top, 10)
            .padding(.horizontal)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(.black)
            .foregroundColor(.white)
            .onChange(of: vm.textRecognizerMode) { mode in
                delegate?.textRecognizerModeChanged(textRecognizerMode: mode)
            }
            .onChange(of: vm.censorMode) { mode in
                delegate?.censorModeChanged(censorMode: mode)
            }
        }
        .background(.black)
    }
}

struct ToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarView(vm: ToolbarViewModel(), delegate: nil)
    }
}

extension ToolbarView {
    var undoRedo: some View {
        HStack(spacing: 12.5) {
            Button {
                vm.undoManager.undo()
                delegate?.redrawRectangle()
            } label: {
                VStack(spacing: 5) {
                    Image(systemName: "arrow.uturn.backward")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .foregroundColor(vm.undoManager.undoStack.count > 0 ? .white : .gray)

            Button {
                vm.undoManager.redo()
                delegate?.redrawRectangle()
            } label: {
                VStack(spacing: 5) {
                    Image(systemName: "arrow.uturn.forward")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .foregroundColor(vm.undoManager.redoStack.count > 0 ? .white : .gray)
        }
    }
    
    var textSelection: some View {
        HStack(spacing: 5){
            Menu {
                Picker("", selection: $vm.detectionMode) {
                    ForEach(DetectionMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.image)
                            .tag(mode)
                    }
                }
            } label: {
                VStack(spacing: 5) {
                    Image(systemName: vm.detectionMode.image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(vm.detectionMode.rawValue)
                        .font(.system(size: 11, weight: .medium))
                }
                .frame(width: 40)
            }
            
            if vm.detectionMode == .auto {
                Menu {
                    Picker("", selection: $vm.textRecognizerMode) {
                        ForEach(TextRecognizerMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.image)
                                .tag(mode)
                        }
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: vm.textRecognizerMode.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text(String(vm.textRecognizerMode.rawValue.split(separator: " ").last ?? ""))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(width: 40)
                }
            } else {
                Menu {
                    Picker("", selection: $vm.manualMode) {
                        ForEach(ManualMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.image)
                                .tag(mode)
                        }
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: vm.manualMode.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text(vm.manualMode.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(width: 40)
                }
            }
        }
    }
    
    var editingOptions: some View {
        HStack(spacing: 0){
            ForEach(CensorMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation {
                        vm.prevCensorMode = vm.censorMode
                        vm.censorMode = mode
                    }
                } label: {
                    VStack(spacing: 5) {
                        if mode == .bar {
                            Rectangle()
                                .frame(width: 20, height: 5)
                                .padding(.vertical, 7.5)
                        } else {
                            Image(systemName: mode.image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                        
                        Text(mode.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .frame(width: mode == .underline || mode == .highlight ? 60 : 40)
                    .foregroundColor(vm.censorMode == mode ? .white : .gray)
                }
                
                if mode == .blend {
                    Rectangle()
                        .frame(width: 1, height: 20)
                        .padding(.horizontal, 10)
                        .offset(y: -7.5)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

protocol ToolbarViewDelegate {
    func textRecognizerModeChanged(textRecognizerMode: TextRecognizerMode)
    func censorModeChanged(censorMode: CensorMode)
    func redrawRectangle()
}

