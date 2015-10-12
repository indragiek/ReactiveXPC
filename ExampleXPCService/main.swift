//  Copyright © 2015 Indragie Karunaratne. All rights reserved.

import ReactiveXPC
import ReactiveCocoa

// Listen for incoming connections, and subscribe to the `inbound` signal
// to receive strings sent by the app, uppercase them, and send them back.
listen { connection in
    connection.inbound
        .ignoreErrors()
        .map(unpackString)
        .ignoreNil()
        .map { $0.uppercaseString }
        .map(pack)
        .observe(connection.outbound)
    connection.resume()
    return true
}
