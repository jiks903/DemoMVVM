//
//  InternetChecker.swift
//  Demo
//
//  Created by Jeegnesh Solanki on 02/05/24.
//

import Foundation
import Network

class InternetConnectivityChecker {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
     var isConnected: Bool = false
    
    // Observer closure for notifying changes in connectivity
    var connectivityChanged: ((Bool) -> Void)?
    
    init() {
        monitor = NWPathMonitor()
        queue = DispatchQueue(label: "InternetConnectivityChecker")
        
        // Start monitoring the network path
        monitor.pathUpdateHandler = { path in
            // Update the connectivity status
            self.isConnected = path.status == .satisfied
            
            // Notify the observer of the connectivity change
            self.connectivityChanged?(self.isConnected)
        }
        
        monitor.start(queue: queue)
    }
    
    // Check current internet connectivity status
    func isInternetAvailable() -> Bool {
        return isConnected
    }
    
    // Stop monitoring the network path
    deinit {
        monitor.cancel()
    }
}
