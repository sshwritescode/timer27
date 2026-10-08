import SwiftUI
import AppKit


struct TimerSlider: View {

    var scrollSensitivity: CGFloat = 0.5
    var swipeSensitivity: CGFloat = 0.5

    // parameters for slider
    var minValue: Double = 1.0
    var maxValue: Double = 120.0
    var sliderWidth: CGFloat = 375.0
    var sliderHeight: CGFloat = 76.0

    // paramters for pill and labels
    let pillWidth: CGFloat = 3
    let pillHeight: CGFloat = 35
    let spacing: CGFloat = 6
    let pillY: CGFloat = 30
    let labelInterval: CGFloat = 5
    
    // gesture and position adjustment values
    @State private var offset: CGFloat = 0.0
    @State private var dragStartOffset: CGFloat = 0.0
    
    // time tracking values
    @Binding var timerValue: Double
    var initialValue: Double

    // create new comments once I figure what everything does
    // flash params - Int:key - Date:value
    @State private var flashStarts: [Int: Date] = [:] // dictionaries for each pill index
    @State private var labelFadeStarts: [Int: Date] = [:] // dictionaries for each pill index
    @State private var lastFlash: Date? 
    private let flashDuration: TimeInterval = 0.35 
    private let flashStagger: TimeInterval = 0.1
    
    // scroll params
    @State private var scrollMonitor: Any?
    @State private var isHovering = false
    @State private var lastScroll: Date?
    private let scrollSnapDelay: TimeInterval = 0.12

    private var currentValue: Double {
        let raw = (sliderWidth / 2 - offset) / (pillWidth + spacing)
        return min(max(Double(raw), minValue), maxValue).rounded()
    }

    private var totalScrollableWidth: CGFloat {
        return CGFloat(maxValue) * (pillWidth + spacing)
    }

    var body: some View {
        //            ---- Diagnostics
        //            Text("current value: \(currentValue, specifier: "%.1f")")
        //            Text("offset: \(offset, specifier: "%.1f")")
        //            Text("\(timerValue, specifier: "%.2f")")
        
        
        // timelineView gives TimeTicks canvas the aniamtable property
        // paused: pauses all animation updates
        // when not paused = redraws every frame
        TimelineView(.animation(paused: lastFlash == nil)) { timeline in // how does paused: work?
            TimerTicks(
                offset: offset,
                selectedValue: currentValue,
                maxValue: maxValue,
                pillWidth: pillWidth,
                pillHeight: pillHeight,
                spacing: spacing,
                pillY: pillY,
                now: timeline.date, // time at time of render
                flashStarts: flashStarts,
                labelFadeStarts: labelFadeStarts,
                flashDuration: flashDuration
            )
        }
        .frame(width: sliderWidth, height: sliderHeight)
        .onHover { hovering in 
            isHovering = hovering
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
//                    offset = dragStartOffset + gesture.translation.width * scrollSensitivity
                    moveSlider(to: dragStartOffset + gesture.translation.width * scrollSensitivity)
                }
                .onEnded { _ in // underscore could be named anything but since it's never used it's best practice to use _
                    snapToNearestTick()
                }
        )
        .onAppear {
            // places the slider at initial value
            offset = sliderWidth / 2 - CGFloat(initialValue / maxValue) * totalScrollableWidth // place in center and i will subtract from it to give offset
            dragStartOffset = offset
            
            if scrollMonitor == nil {
                scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in 
                    handleScroll(event)
                }
            }
        }
        .onDisappear {
            if let scrollMonitor {
                NSEvent.removeMonitor(scrollMonitor)
            }
            scrollMonitor = nil
        }

        .task(id: lastScroll) {
            guard lastScroll != nil else { return }
            do {
                try await Task.sleep(for: .seconds(scrollSnapDelay))
            } catch {
                return
            }
            lastScroll = nil
            snapToNearestTick()
        }
        // task runs when id changes
        .task(id: lastFlash) {
            guard lastFlash != nil else { return }
            do {
                try await Task.sleep(for: .seconds(flashDuration)) // set to flashDuration to ensure all flash animations are given a chance to play out before animation is paused in TimelineView(paused:)
            } catch {
                return 
            }
            flashStarts.removeAll()
            labelFadeStarts.removeAll()
            lastFlash = nil
        }
    }
    
    // integral for calculating offset from different sources
    private func moveSlider(to newOffset: CGFloat) {
        let previousValue = currentValue // captured before offset changes
        let rightOffset = -totalScrollableWidth + sliderWidth / 2 // -703.5
        let leftOffset = sliderWidth / 2 // 136.5
        // for min-max below
        // if offset < -703.5 ? offset = -703.5
        // if offset > 136.5 (half slider width) ? offset = 136.5
        offset = min(max(newOffset, rightOffset), leftOffset)
        timerValue = currentValue

        // flash the pills whose selection changed and adds haptics ONLY IF CHANGE
        if currentValue != previousValue {
            flashPills(from: Int(previousValue), to: Int(currentValue))
            
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now) // adds haptics

        }
    }
    
    private func handleScroll( _ event: NSEvent) -> NSEvent? {
        guard isHovering else { return event }
        guard abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) else { return event } // scrollX MUST be > scrollY else return - prevents vertical scrolling
        
        let delta = event.hasPreciseScrollingDeltas ? event.scrollingDeltaX * swipeSensitivity : event.scrollingDeltaX * (pillWidth + spacing) // idk how it knows which one to choose
        moveSlider(to: offset + delta) // why is it offset + delta? shouldn't it be dragStartOffset
        
        dragStartOffset = offset
        lastScroll = Date()
        return nil
    }
    
    // I don't understand how this snaps to the center (what the Claude's now deleted comment said)
    private func snapToNearestTick() {
        withAnimation(.easeInOut(duration: 0.15)) {
            offset = sliderWidth / 2 - CGFloat(currentValue) * (pillWidth + spacing)
            dragStartOffset = offset
        }
    }
    
    private func flashPills(from previousValue: Int, to newValue: Int) { // from/to are built in labels for function calls rather than using their param names
        let now = Date() // date initialized
        let step = newValue > previousValue ? 1 : -1
    
        //                  from: 15 + (1) to 20 by 1 step
        for value in stride(from: previousValue + step, through: newValue, by: step) {
            let start = now.addingTimeInterval(-Double(abs(newValue - value)) * flashStagger) // .addingTimerInterval is in seconds
            flashStarts[value] = start // pushes in delayed start value or expected start value
            labelFadeStarts[step > 0 ? value : value + 1] = start
        }
        lastFlash = now
    }
}


private struct TimerTicks: View, Animatable {
    var offset: CGFloat
    var selectedValue: Double
    let maxValue: Double
    let pillWidth: CGFloat
    let pillHeight: CGFloat
    let spacing: CGFloat
    let pillY: CGFloat
    let now: Date
    let flashStarts: [Int: Date]
    let labelFadeStarts: [Int: Date]
    let flashDuration: TimeInterval
    
    // why is offset initialized like this?
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    var body: some View {
        Canvas (
            opaque: true,
            colorMode: .linear,
            rendersAsynchronously: false
        ) { context, size in
            
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .color(Color.backgroundColor))
            
            let centerY = size.height / 2
            let pitch = pillWidth + spacing // is it better to put this here for computation purposes or to have it computed once and put in state variable else where?

            // dot
            let dotDiameter: CGFloat = 4
            let dotGap: CGFloat = 4
            let dot = CGRect(
                x: size.width / 2 - dotDiameter / 2,
                y: pillY + pillHeight + dotGap,
                width: dotDiameter,
                height: dotDiameter
            )
            context.fill(Path(ellipseIn: dot), with: .color(Color.primaryColor))

            // wtf does this mean
            let firstIndex = max(Int(((-offset) / pitch).rounded(.down)) - 1, 0)
            let lastIndex = min(Int(((size.width - offset) / pitch).rounded(.up)) + 1, Int(maxValue))
            guard firstIndex <= lastIndex else { return }
            
            // swapped to indicies instead of hardcoded 0...121
            for i in firstIndex...lastIndex {

                let pillX = CGFloat(i) * pitch + offset
                let pill = CGRect(x: pillX - pillWidth / 2, y: pillY, width: pillWidth, height: pillHeight) // the position and dimensions of shape
                let roundedRect = Path(roundedRect: pill, cornerRadius: 10) // path creates a shape out of the space you provide

                let isSelected = Double(i) <= selectedValue // slightly misleading variable name
                let regularColor = isSelected ? Color.primaryColor : Color.secondaryColor
                var pillColor = regularColor
                var labelColor = regularColor

                // a pill that just reached the center starts as tertiary and fades to its regular colour
                if let flashStart = flashStarts[i] {
                    let progress = min(now.timeIntervalSince(flashStart) / flashDuration, 1) // is this being recalculated at every render? -> yes
                    // timeIntervalSince increases -> when divided by 0.35 increases from 0 to eventually >1 at which point the min() ends up choosing 1
                    // this causes the fade to go from 0 (tertiary start) to 1 (regularColor)
                    // initially there is a point where diff b/w timeIntervalSince and flashStart[i] is close to 0
                    pillColor = Color.tertiaryColor.mix(with: regularColor, by: progress)
                }

                // a label whose selection just changed fades from its old colour to its new colour
                if let fadeStart = labelFadeStarts[i] {
                    let progress = min(now.timeIntervalSince(fadeStart) / flashDuration, 1) // 0 → 1
                    let previousColor = isSelected ? Color.secondaryColor : Color.primaryColor
                    labelColor = previousColor.mix(with: regularColor, by: progress)
                }

                context.fill(roundedRect, with: .color(pillColor))

                if (i % 5 == 0) {
                    let label = Text(verbatim: "\(i)").font(.system(size: 15, weight: .medium))
                    var resolvedLabel = context.resolve(label)
                    resolvedLabel.shading = .color(labelColor)
                    context.draw(resolvedLabel, at: CGPoint(x: pillX, y: centerY / 2.25), anchor: .center)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var timerValue = 15.0
    TimerSlider(timerValue: $timerValue, initialValue: 15.0)
}
