//
//  TopToolbarView.swift
//  Blackout
//
//  Created by Joses Solmaximo on 03/03/23.
//

import SwiftUI

struct TopToolbarView: View {
    @ObservedObject var vm: ToolbarViewModel
    
    let delegate: TopToolbarViewDelegate?
    
    init(vm: ToolbarViewModel, delegate: TopToolbarViewDelegate?) {
        self._vm = ObservedObject(wrappedValue: vm)
        self.delegate = delegate
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation {
                    vm.toolbarState.isOverlayVisible.toggle()
                    delegate?.isOverlayVisibleChanged()
                }
            } label: {
                Image(systemName: vm.toolbarState.isOverlayVisible ? "rectangle" : "rectangle.slash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17.5, height: 17.5)
            }
            .frame(width: 30, height: 30)
            .foregroundColor(.white)
            .background(
                Color(uiColor: UIColor(red: 59/255, green: 59/255, blue: 60/255, alpha: 1))
                    .cornerRadius(5)
            )
            
            if vm.isRecognizingText {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                        .padding(.leading, 5)
                    
                    Text("Detecting Text")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.trailing, 5)
                }
                .frame(height: 30)
                .background(
                    Color(uiColor: UIColor(red: 59/255, green: 59/255, blue: 60/255, alpha: 1))
                        .cornerRadius(5)
                )
            }
            
            Spacer()
        }
        .padding(10)
    }
}

struct TopToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        TopToolbarView(vm: ToolbarViewModel(), delegate: nil)
    }
}

protocol TopToolbarViewDelegate {
    func isOverlayVisibleChanged()
}
