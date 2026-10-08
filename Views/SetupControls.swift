//
//  SetupControls.swift
//  timer
//
//  Created by Shehryar Manzar on 2026-09-24.
//

import SwiftUI
import Glur
import GlurBackdrop

struct SetupControls: View {
    
    var timerData: TimerData
    var sliderBinding: Binding<Double>
    var isRunning: Bool
    
    var body: some View {
        VStack {
            ZStack(alignment: .center) {
                TimerSlider(timerValue: sliderBinding, initialValue: timerData.initialValue)
                Rectangle()
                    .fill(Color.backgroundColor)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.backgroundColor, location: 0.35),
                                .init(color: Color.backgroundColor.opacity(0), location: 1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay {
                        GlurView(radius: 1.0, offset: 0, interpolation: 0.6, direction: .left)
                            .frame(width: 100, height: 75)
                    }
                    .frame(width: 120, height: 75)
                    .frame(maxWidth: .infinity, alignment: .leading) // overrides the ZStack's .center alignment for this child only
                    .allowsHitTesting(false)
                Rectangle()
                    .fill(Color.backgroundColor)
                    .mask(
                        LinearGradient(
                            // location can be set to 0.25 for more "accurate" look but causes uneveness
                            gradient: Gradient(stops: [
                                .init(color: Color.backgroundColor, location: 0.35),
                                .init(color: Color.backgroundColor.opacity(0), location: 1)
                            ]),
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                    )
                    .overlay {
                        GlurView(radius: 1.0, offset: 0, interpolation: 0.6, direction: .right)
                            .frame(width: 110, height: 75)
                    }
                    .frame(width: 120, height: 75)
                    .frame(maxWidth: .infinity, alignment: .trailing) // overrides the ZStack's .center alignment for this child only
                    .allowsHitTesting(false)   
            }
            .compositingGroup() // this one line fixes render timing issues
            HStack {
                Button {
                    withAnimation(.bouncy) { // recomputes views body & since both anims change height = animation
                        timerData.timeRemaining = Int(timerData.timerValue) * 60
                        timerData.initialValue = timerData.timerValue // when timer restarts it sticks to last chosen time
                        timerData.start(minutes: timerData.timerValue) // you could use initialValue but Text uses timerValue == keep consistency == best choice
                    }
                } label: {
                    Text("Start Timer")
                        .font(.system(size: 17, weight: .semibold))
                        .padding(5)
                }
                .buttonBorderShape(.capsule)
                Spacer()
                Text("\(timerData.timerValue, specifier: "%.0f"):00").font(.system(size: 37, weight: .light).monospacedDigit())
            }
            .padding(.horizontal, 30)
        }
        .transition(.asymmetric(insertion: .opacity, removal: .identity)) // two separate animations - insertion = opacity, removal = no effect, just remove
    }
}
