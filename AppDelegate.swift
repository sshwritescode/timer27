//
//  AppDelegate.swift
//  timer
//
//  Created by Shehryar Manzar on 2026-09-14.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var contentWindow: NSWindow? // is this supposed to be a NSWindow or panel -> WINDOW bc NSPanel is a subclass of NSWindow
    var statusBarItem: NSStatusItem! // it is possible to create multiple buttons for one app
    var statusMenu: NSMenu!
    let timerData = TimerData()
    private var statusItemObserver: Task<Void, Never>?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // .accessory !allow dock or menubar - switch to .regular
        
        // var statusBar: NSStatusBar!   <- is not needed to create a statusBarItem - .system in the line below lets me access macs menu bar not a brand new instance
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.autosaveName = "TimerStatusItem"
        statusBarItem.behavior = [.terminationOnRemoval] // temporary until I find a work around
        
        if let button = statusBarItem.button {
            button.action = #selector(onClick) // NSButton requires a objc selector - this one contains all the functions that run when different mouse buttons are clicked
            // firing on mouse down = the right-click menu ran nested inside unfinished click
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
        updateStatusBarTitle()

        observeStatusItemWindow()
        
        statusMenu = NSMenu()
        statusMenu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")) // i think a shortcut could be created???
//        menu.addItem(.separator()) // if I wanted for more options

        // normally Swift adds self. for you like it did above
        // inside a function closure thats stored and run later, the closure has to take self with it so it knows who to reference since ApplicationDidFinishLaunching happens only once at the beginning
        // Swift forces you explicitly declare it so you know you have a strong reference
        timerData.onUpdate = { [weak self] in
            guard let self else { return }
            self.updateStatusBarTitle()
        }

        showContentWindow()
    }
    
    private func updateStatusBarTitle() {
        let title = timerData.formattedTime // sets time string
        let font = NSFont.monospacedDigitSystemFont(ofSize: 0, weight: .regular) // sets font

        // the font is baked into the attributed string so the status bar button can't override it
        // baselineOffset nudges the text vertically: positive moves it up, negative moves it down
        statusBarItem.button?.attributedTitle = NSAttributedString(
            string: title,
            attributes: [.font: font, .baselineOffset: -0.5]
        )

        // fixed width sized for 5 digits ("000:00") so the status item never changes width
        // when the timer crosses between 4 and 5 digits - measuring "0" keeps it constant
        let width = ("000:00" as NSString).size(withAttributes: [.font: font]).width
        let length = ceil(width) + 6 // padding for the button's insets
        if statusBarItem.length != length {
            statusBarItem.length = length
        }
    }

    // auto adjusts position when the statusButton.window moves
    private func observeStatusItemWindow() {
        guard let statusWindow = statusBarItem.button?.window else { return }

        statusItemObserver = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: NSWindow.didMoveNotification, object: statusWindow) {
                self?.positionPanel()
            }
        }
    }

    // change name to showContentPanel bc it's a panel not a window
    func showContentWindow() {
        self.closeReviewWindow()
        
        let contentPanel = ContentPanel(timerData: timerData) // initializing an instance of appkit component
        
        contentWindow = contentPanel
        positionPanel()
        
        contentPanel.onDoubleClick = { [weak self] in
            self?.positionPanel(animated: true)
        }

//        contentPanel.orderFront(true)
        contentPanel.makeKeyAndOrderFront(nil)
        contentPanel.makeKey() // is this redundant?
    }
    
    private func closeReviewWindow() {
        if let window = contentWindow {
            window.close()
            contentWindow = nil
        }
    }
    
    // centers the panel underneath the status item
    private func positionPanel(animated: Bool = false) {
        guard let panel = contentWindow as? ContentPanel,
              let button = statusBarItem.button else { return }
        panel.position(below: button, animated: animated)
    }    
    
    // visibility of panel is completely controlled here
    @objc private func togglePanel() {
        timerData.togglePanel()
    }
    
    @objc private func toggleMenu() {
        statusBarItem.menu = statusMenu
        statusBarItem.button?.performClick(nil)
        statusBarItem.menu = nil
    }
    
    @objc private func onClick() {
        if let event = NSApp.currentEvent, event.isRightClick {
            toggleMenu()
        } else {
            togglePanel()
        }
    }
}

extension NSEvent {
    var isRightClick: Bool {
        let rightClick = (self.type == .rightMouseUp) // swapped to mouse up
        return rightClick
    }
}
