//  Copyright © 2015 Indragie Karunaratne. All rights reserved.

import ReactiveXPC
import ReactiveCocoa

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
