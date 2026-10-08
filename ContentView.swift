//
//  ContentView.swift
//  timer
//
//  Created by Shehryar Manzar on 2026-09-14.
//

import SwiftUI
import AppKit

// swiftui view
struct ContentView: View {
    
    var timerData: TimerData
    var onHidden: () -> Void = {} // called once the collapse animation finishes so the panel can order out
    var onDoubleClick: () -> Void = {} // recenters panel under the status item
    
    @State private var isExpanded = true

    private let frameWidth: CGFloat = 335

    
    // not easy to do ternary operators with enums w/ multiple conditions - better to do compute property
    // could also do this = height: [.running, .paused].contains(mode) ? 75 : 165,
    var frameHeight: CGFloat { 
        switch phase {
        case .setup:
            return 165
        default:
            return 75
        }
    }
    
    // making this a computed property runs it every time it is accessed
    private var phase: TimerData.Phase {
        get {
            timerData.phase
        }
        set {
            timerData.phase = newValue
        }
    }
    
    // gets and sets timerValue but only during .setup (prevents accidental gestures when mode == .running .paused)
    private var sliderBinding: Binding<Double> {
        Binding(
            get: { timerData.timerValue },
            set: { newValue in
                guard phase == .setup else { return }
                timerData.timerValue = newValue
            }
        )
    }
    
    // passing in timerData to child lets components accessing props to re-render
    // therefore - do not pass in properties from contentview to the child bc that will cause contentView to re-render rather than the components
    
    var body: some View {
        VStack {
            switch phase {
            case .setup:
                SetupControls(
                    timerData: timerData,
                    sliderBinding: sliderBinding,
                    isRunning: phase == .setup,
                )
            case .running, .paused, .ended:
                RunningControls(
                    timerData: timerData,
                    isPaused: phase == .paused,
                    timerEnded: phase == .ended,
                )
            }
        }
        .padding(.vertical, 40)
        .frame(width: frameWidth, height: frameHeight, alignment: .center)
        .foregroundStyle(Color.primaryColor)
        .background {
            // apply tap to background only
            Color.backgroundColor.onTapGesture(count: 2) { onDoubleClick() }
        }
        .gesture(WindowDragGesture()) // allows window drag without impacting slider or content underneath
        .clipShape(RoundedRectangle(cornerRadius: 50))
        // use mask instead of scaling - better for animatins
        .mask {
            RoundedRectangle(cornerRadius: 50)
                .frame(width: isExpanded ? frameWidth : frameHeight, height: frameHeight)
        }
        .opacity(isExpanded ? 1 : 0)
        .onChange(of: timerData.isPanelVisible) { _, isVisible in
            if isVisible {
                withAnimation(.bouncy(duration: 0.45)) {
                    isExpanded = true
                }
            } else {
                withAnimation(.bouncy(duration: 0.65)) {
                    if phase != .setup {
                        isExpanded = false                      
                    }
                    onHidden()
                } 
                // re-enable this 
//                completion: {
//                    guard !timerData.isPanelVisible else { return }
//                    onHidden()
//                }
            }
        }
    }
}


// find out how to fix the bug there in contentView
// it's missing dismiss call - how do i give it that in the preview?
//#Preview {
//    ContentView()
//}
