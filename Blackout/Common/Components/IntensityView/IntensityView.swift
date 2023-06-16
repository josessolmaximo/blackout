//
//  IntensityView.swift
//  Blackout
//
//  Created by Joses Solmaximo on 24/02/23.
//

import SwiftUI

struct IntensityView: View {
    @ObservedObject var vm: ToolbarViewModel
    let delegate: IntensityViewDelegate?
    
    init(vm: ToolbarViewModel, delegate: IntensityViewDelegate?) {
        self._vm = ObservedObject(wrappedValue: vm)
        self.delegate = delegate
    }
    
    var body: some View {
        if vm.censorMode == .bar || vm.censorMode == .highlight || vm.censorMode == .underline {
            VStack(spacing: 0) {
                Spacer()
                
                ColorPicker("", selection: vm.censorMode == .bar ? $vm.barColor : vm.censorMode == .highlight ? $vm.highlightColor : $vm.underlineColor)
                    .labelsHidden()
            }
            .frame(width: 35, height: 80)
        } else {
            VStack(spacing: 0) {
                let maxDisabled = vm.censorMode == .blur ? vm.toolbarState.blurRadius == 100 : vm.toolbarState.pixelScale == 100
                let minDisabled = vm.censorMode == .blur ? vm.toolbarState.blurRadius == 5 : vm.toolbarState.pixelScale == 5
                
                HStack {
                    Button(action: {
                        vm.changeIntensity(change: 5)
                        delegate?.intensityChanged(intensityView: self)
                    }, label: {
                        ZStack {
                            Color.clear
                            
                            Image(systemName: "plus")
                        }
                    })
                    .disabled(maxDisabled)
                    .foregroundColor(maxDisabled ? .gray : .white)
                }
                .frame(height: 25)
                HStack {
                    Text(vm.censorMode == .blur ? "\(vm.toolbarState.blurRadius)" : "\(vm.toolbarState.pixelScale)")
                        .fontWeight(.semibold)
                }
                .frame(height: 30)
                
                HStack {
                    Button(action: {
                        vm.changeIntensity(change: -5)
                        delegate?.intensityChanged(intensityView: self)
                    }, label: {
                        ZStack {
                            Color.clear
                            
                            Image(systemName: "minus")
                        }
                    })
                    .disabled(minDisabled)
                    .foregroundColor(minDisabled ? .gray : .white)
                }
                .frame(height: 25)
            }
            .foregroundColor(.white)
            .frame(width: 35, height: 80)
            .background(
                Color(uiColor: UIColor(red: 59/255, green: 59/255, blue: 60/255, alpha: 1))
                    .cornerRadius(5)
            )
        }
    }
}

struct IntensityView_Previews: PreviewProvider {
    static var previews: some View {
        IntensityView(vm: ToolbarViewModel(), delegate: nil)
    }
}

protocol IntensityViewDelegate {
    func intensityChanged(intensityView: IntensityView)
}
