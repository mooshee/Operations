//
//  NetworkOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 01/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation


/**
An Operation which is a simple wrapper around `NSURLSessionTask`.

Note that the task will still need to be configured with a delegate
as usual. Typically this operation would be used after the task is
setup, so that conditions or observers can be attached.

*/
public class URLSessionTaskOperation: Operation {

    enum KeyPath: String {
        case State = "state"
    }

    public let task: NSURLSessionTask
    private var hasFinished: Bool = false
    private let lock: NSLock
    
    public init(task: NSURLSessionTask) {
        assert(task.state == .Suspended, "NSURLSessionTask must be suspended, not \(task.state)")
        self.task = task
        self.lock = NSLock()
        super.init()
        addObserver(CancelledObserver { _ in
            task.cancel()
        })
    }

    public override func execute() {
        assert(task.state == .Suspended, "NSURLSessionTask resumed outside of \(self)")
        task.addObserver(self, forKeyPath: KeyPath.State.rawValue, options: [], context: &URLSessionTaskOperationKVOContext)
        task.resume()
    }

    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &URLSessionTaskOperationKVOContext else { return }

        /**
         *  The task.state could be set to .Complete firing this logic multiple times.
         *  Use a lock and the hasFinished flag to ensure this only happens once.
         */
//        lock.lock()
        
        if object === task && task.state == .Completed && keyPath == KeyPath.State.rawValue && !hasFinished {
//            hasFinished = true
            task.removeObserver(self, forKeyPath: KeyPath.State.rawValue)
            finish()
        }
        
//        lock.unlock()
    }
}

// swiftlint:disable variable_name
private var URLSessionTaskOperationKVOContext = 0
// swiftlint:enable variable_name
