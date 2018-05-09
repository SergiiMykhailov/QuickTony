//
//  BackgroundTasker.swift
//  Visheo
//
//  Created by Ivan on 4/26/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import Foundation

final class CompleteOperation : Operation {
    private let completionHandler : () -> ()
    
    init(withCompletion completionHandler: @escaping () -> ()) {
        self.completionHandler = completionHandler
    }
    
    override func main() {
        self.completionHandler()
    }
}

final class LongOperation : Operation {
    let delay: UInt32
    
    init(withDelay delay: UInt32) {
        self.delay = delay
    }
    
    override func main () {
        usleep(delay)
    }
}

class BackgroundTasker {
    private let operationQueue = OperationQueue()
    
    var lastOperationCalled : Operation?
    
    func mapOperation(withDelay delay: UInt32, completion: @escaping () -> ()){
        lastOperationCalled?.cancel()
        
        let completeOperation = CompleteOperation(withCompletion: completion)
        let operation = LongOperation(withDelay: delay)
        completeOperation.addDependency(operation)
        
        lastOperationCalled = completeOperation
        
        operationQueue.addOperation(operation)
        OperationQueue.main.addOperation(completeOperation)
    }
}
