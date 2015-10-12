//  Copyright © 2015 Indragie Karunaratne. All rights reserved.

import ReactiveCocoa

public extension SignalType {
    /// Returns a new signal that ignores all errors sent by the receiver,
    /// representing them as interrupted events instead.
    public func ignoreErrors() -> Signal<Value, NoError> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .Next(let value):
                    sendNext(observer, value)
                case .Completed:
                    sendCompleted(observer)
                case .Interrupted, .Error:
                    sendInterrupted(observer)
                }
            }
        }
    }
}
