import Observation
import AppKit

// seems to have bug where the longer a timer runs the more seconds it skips - idk why this happens

@Observable
final class TimerData {
    
    var timeRemaining: Int = 0 // could this be updated to a double to stop conversions throughout
    var timerValue: Double = 15
    var initialValue: Double = 15
    var restartValue: Double = 15

    var fadeOutTime: Int = 0
    var fadeOutValue: Int = 10
        
    var endDate: Date?
    var onUpdate: (() -> Void)? // is a slot that holds some function to call later
    private var timer: Timer?
    private var sound: NSSound?
    var alarmPlaying = false
    var isPanelVisible = true
    
    private static let ringtoneDir = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/ToneLibrary.framework/Versions/A/Resources/Ringtones")
    
    var formattedTime: String {
        String(
            format: "%02d:%02d",
            Int(timeRemaining) / 60,
            Int(timeRemaining) % 60
        )
    }
    
    func showPanel() { isPanelVisible = true }
    func hidePanel() { isPanelVisible = false }
    func togglePanel() { isPanelVisible.toggle() }
    
    enum Phase {case setup, running, paused, ended}
    var phase: Phase = .setup
    
    func start(minutes: Double) {
        // diagnostic
//        endDate = Date()
//        timeRemaining = 0
        
        // proper code
        endDate = Date().addingTimeInterval(minutes * 60)
        timeRemaining = Int(minutes) * 60
        fadeOutTime = timeRemaining - fadeOutValue
        restartValue = minutes
        onUpdate?() // does this create the instance of a function onUpdate? -> no it calls it - declared in AppDelegate
        startTimer()
        
        phase = .running
        
//        print("timer started")
        
        // I tried to use a dispatch in start - it would run regardless of if timer was on or off
        // I swapped to time based by creating fadeOutTime - this looks like claude wrote these looooooool
    }
    
    func stop() {
        timer?.invalidate() // shuts down instance of timer
        timer = nil // set to nothing for added security
        endDate = nil
        
        if phase != .ended {
            phase = .paused
        }
    }
    
    func reset() {
        timeRemaining = 0
        onUpdate?() // calls onUpdate = update any text on menu bar
        
        // edit this to if phase == .ended when i can test
        if alarmPlaying {
            stopRingtone()
        }
        
        phase = .setup
    }
    
    func resume() {
        endDate = Date().addingTimeInterval(Double(timeRemaining))
        startTimer()
        phase = .running
    }
    
    // clean this shit up
    func restart() {
        
        stopRingtone()
        
        timeRemaining = Int(restartValue) * 60 // convert to seconds
        onUpdate?()
        resume()
    }
    
    func playRingtone(toneNamed name: String = "Radial-EncoreInfinitum") {
        let url = Self.ringtoneDir.appendingPathComponent("\(name).m4r") 

        if let ringtone = NSSound(contentsOf: url, byReference: true) {
            sound = ringtone
        } else {
            sound = NSSound(named: "Glass") 
        }
        sound?.loops = true
        sound?.play()
    }
    
    func stopRingtone() {
        sound?.stop()
        alarmPlaying = false
    }
    
    private func startTimer() {
        timer?.invalidate() // stop any pre-existing timers 
        
        // timer runs every second and repeats
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.update() // recalculates time remaining and calls onUpdate = update any text on menu bar
        }
        // .common mode keeps the timer firing while the run loop is in .eventTracking
        // (e.g. while the status bar menu is open), instead of only in .default mode
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    private func update() {
        guard let endDate else { return }
        
        let secondsLeft = endDate.timeIntervalSinceNow
        timeRemaining = max(0, Int(secondsLeft.rounded(.up)))
        onUpdate?() // calls onUpdate = update ALL timer related text --> is this tight coupling to the appDelegate?????
            
        // hides panel after specified time
//        if timeRemaining == fadeOutTime {
//            hidePanel()
//        }
        
        // when no time left
        if timeRemaining == 0 {
            stop()
            reset()
            alarmPlaying = true
            isPanelVisible = true
            playRingtone()
            phase = .ended
        }
    }

}

// name of radial in system files
// Radial-EncoreInfinitum
