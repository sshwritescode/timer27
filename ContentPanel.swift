//
//  ContentPanel.swift
//  timer
//
//  Created by Shehryar Manzar on 2026-09-14.
//

import AppKit
import SwiftUI

class ContentPanel: NSPanel {
    private let timerData: TimerData
    private var visibilityTask: Task<Void, Never>? // Gotta do a thorough understanding of everywhere this is used
    var onDoubleClick: (() -> Void)?
    
    // init is necessary for all inherited subclasses - NSPanel inherits from NSwindow and ContentPanel inherits NSPanel
    // all necessary work for each of those classes are done in super.init to ensure they are initialized correctly
    init(timerData: TimerData) {
        self.timerData = timerData
        super.init( // wtf does super.init() do?
            contentRect: .zero, 
            styleMask: [.borderless, .nonactivatingPanel], // removing .titled removed the top spacing
            backing: .buffered, // ignore the other options those are old
            defer: true
        )
        setupWindow()
        setupContentView()
        observeVisibility()
    }
    
    override var canBecomeKey: Bool { true } // necessary for disabling keyboard sounds
    override func keyDown(with event: NSEvent) {} // disables keyboard sounds

    // resets the mouse when entering
    override func mouseEntered(with event: NSEvent) {
        makeKey()
        NSCursor.arrow.set()
    }
    
    // restores mouse to default on move - especially useful when switching tabs and cursor changes
    // acts as added security
    override func mouseMoved(with event: NSEvent) {
        NSCursor.arrow.set()
    }
    
    private func setupWindow() {
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        level = .floating
        isMovableByWindowBackground = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        
        collectionBehavior = [ 
            .canJoinAllSpaces,
            .stationary
        ]
    }
    
    private func setupContentView() {
        let contentView = ContentView(timerData: timerData, onHidden: { [weak self] in 
            guard let self else { return }
            self.orderOut(nil)
        }, onDoubleClick: { [weak self] in
            guard let self else { return }
            self.onDoubleClick?()
        }) // builds swiftui view
        
        // allows you to host a swiftui view in appkit view
        let hostingView = NSHostingView(rootView: contentView) // appkit wrapper for swiftui
        self.contentView = hostingView // sets NSPanels contentView

        // tracks the cursor in window to apply correct cursor type
        hostingView.addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))

        // sets panelSize to be dependent on the hostingView
        hostingView.setFrameSize(hostingView.fittingSize)
        setContentSize(hostingView.frame.size)
    }
    
    // centers the panel horizontally under the status item button
     // Inheritance: NSObject -> NSResponder -> NSView -> NSControl -> NSButton -> NSStatusBarButton
    // Through NSView I can access .window
    func position(below button: NSStatusBarButton, animated: Bool = false) {
        
        // check if button is in menu bar else do not position item
        guard let buttonWindow = button.window else { return } // window = container that holds button = menubar 

        let yPadding: CGFloat = 10

        let buttonBounds = button.bounds // gets button size (x, y)
        let windowRect = button.convert(buttonBounds, to: nil) // gets position of button inside the window 
        let buttonRect = buttonWindow.convertToScreen(windowRect) // converts window coordinate to screenspace coordinate
        
        // diagnostic
//        print("Button Size: \(buttonBounds)")
//        print("Button Size Type: \(type(of: (buttonBounds)))")
//        print("Window Coordinate: \(windowRect)")
//        print("Window Coordinate Type: \(type(of: (windowRect)))")
//        print("ButtonRect Value: \(buttonRect)")
//        print("ButtonRect Type: \(type(of: (buttonRect)))")
//        

        // frame is a property of NSPanel -> NSWindow
        // starting position of panel
        let xPosition = buttonRect.midX - self.frame.width / 2

        // anchors the top edge so height changes between phases grow downward
        // AppKit frames use a bottom-left origin, so subtract the height to keep the same top edge
        var target = self.frame
        target.origin = NSPoint(x: xPosition, y: buttonRect.minY - yPadding - frame.height)
        setFrame(target, display: true, animate: animated)
    }
    
    // might be able to merge these two functions into one
    // applies visibility to self (NSPanel) based on timerData panelVisibility
    private func observeVisibility() {
        let timerData = timerData
        visibilityTask = Task { [weak self] in
            for await isVisible in Observations({ timerData.isPanelVisible }) {
                guard let self else { return }
                if isVisible {
                    makeKeyAndOrderFront(nil)
                }
            }
        }
    }
}
