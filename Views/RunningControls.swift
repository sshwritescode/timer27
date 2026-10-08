//
//  RunningControls.swift
//  timer
//
//  Created by Shehryar Manzar on 2026-09-24.
//

import SwiftUI

struct RunningControls: View {
    
    var timerData: TimerData 
    var isPaused: Bool
    var timerEnded: Bool
    private var symbolIcon: String {
        if timerEnded { return "arrow.clockwise"}
        return isPaused ? "play.fill" : "pause"
    }
    
    @State private var shakeStrength: Double = 0.0
    
    var body: some View {
        HStack {
            HStack {
                Button(action: {
                    if timerEnded {
                        timerData.restart()
                    } else {
                        isPaused ? timerData.resume() : timerData.stop()  
                    }
                }) {
                    Image(systemName: symbolIcon).font(.system(size: 20, weight: timerEnded ? .bold : .black)) 
                        .frame(width: 22, height: 22)
                        .padding(10)
                        .foregroundStyle(Color.primaryColor)
                        .background(Color.secondaryColor, in: .circle)
                }
                .buttonStyle(.plain)
                .buttonBorderShape(.circle)
                Button(action: {
                    withAnimation(.bouncy) { // recomputes views body & since both anims change height = animation
                        timerData.stop() // sets phase = .paused
                        timerData.reset() // sets phase = .setup
                    }       
                }) {
                    Image(systemName: "xmark").font(.system(size: 20, weight: .bold))   
                        .frame(width: 22, height: 22)
                        .padding(10)
                        .foregroundStyle(.white.secondary)
                        .background(Color.white.tertiary, in: .circle)
                }
                .buttonStyle(.plain)
                .buttonBorderShape(.circle)   
            }
//                        .frame(maxWidth: .infinity, alignment: .leading) // takes the slack and pins the buttons to the leading edge
            Spacer()
            HStack (alignment: .lastTextBaseline) {
                Text("Timer").font(.system(size: 20, weight: .semibold))
                Text(timerData.formattedTime)
                    .font(.system(size: 37, weight: .light).monospacedDigit()) // monospacedDigit() prevents movement = all have same width
            }
            .textRenderer(ShakeRenderer(strength: shakeStrength, intensity: timerEnded ? 1 : 0))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.45).repeatForever(autoreverses: true)) {
                shakeStrength = 3
            }
        }
        .padding(.horizontal, 20)
    }
}

@Animatable // this is like magic
struct ShakeRenderer: TextRenderer {
    var strength: Double
    var intensity: Double
    
    func draw(
        layout: Text.Layout, // text layout to render
        in context: inout GraphicsContext // graphics context to draw text into 
    ) {
        for line in layout {
            for run in line {
                for glyph in run {
                    var copy = context // what is this and why is it important
                    let xOffset = Double.random(in: -strength...strength) * intensity
                    let yOffset = Double.random(in: -strength...strength) * intensity
                    
                    copy.translateBy(x: xOffset, y: yOffset)
                    copy.draw(glyph)   
                }
            }
        }
    }
}
