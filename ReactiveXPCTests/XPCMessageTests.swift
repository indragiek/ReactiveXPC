//  Copyright © 2015 Indragie Karunaratne. All rights reserved.

import XCTest
import ReactiveXPC

class XPCMessageTests: XCTestCase {
    private func toAndFromXPCMessage(object: XPCMessage) -> XPCMessage {
         return XPCMessage(xpcObject: object.toXPCObject())!
    }
    
    func testArrayMarshalling() {
        let numbers: [Int64] = [1, 2, 3]
        let numbersXPC = numbers.map { XPCMessage.Int64($0) }
        switch toAndFromXPCMessage(XPCMessage.Array(numbersXPC)) {
        case .Array(let a):
            var resultNumbers = [Int64]()
            for innerObject in a {
                switch innerObject {
                case .Int64(let value):
                    resultNumbers.append(value)
                default:
                    XCTFail("Expected inner object to be Int64 value")
                }
            }
            XCTAssertEqual(numbers, resultNumbers)
        default:
            XCTFail("Expected array value")
        }
    }
    
    func testArrayEquality() {
        let numbers = [1, 2, 3].map { XPCMessage.Int64($0) }
        let xpcNumbers = XPCMessage.Array(numbers)
        XCTAssertEqual(xpcNumbers, xpcNumbers)
        let differentNumbers = [4, 5, 6].map { XPCMessage.Int64($0) }
        XCTAssertNotEqual(xpcNumbers, XPCMessage.Array(differentNumbers))
    }
    
    func testBooleanMarshalling() {
        let value = true
        switch toAndFromXPCMessage(XPCMessage.Boolean(value)) {
        case .Boolean(let resultValue):
            XCTAssertEqual(resultValue, value)
        default:
            XCTFail("Expect boolean value")
        }
    }
    
    func testBooleanEquality() {
        let xpcTrue = XPCMessage.Boolean(true)
        XCTAssertEqual(xpcTrue, xpcTrue)
        XCTAssertNotEqual(xpcTrue, XPCMessage.Boolean(false))
    }
    
    func testDataMarshalling() {
        var bytes = [0xDE, 0xAD, 0xBE, 0xEF] as [UInt8]
        let data = NSData(bytes: &bytes, length: bytes.count)
        switch toAndFromXPCMessage(XPCMessage.Data(data)) {
        case .Data(let resultData):
            XCTAssertEqual(resultData, data)
        default:
            XCTFail("Expected data value")
        }
    }
    
    func testDataEquality() {
        var bytes = [0xDE, 0xAD, 0xBE, 0xEF] as [UInt8]
        let data1 = NSData(bytes: &bytes, length: bytes.count)
        let data2 = NSData(bytes: &bytes, length: bytes.count)
        XCTAssertEqual(XPCMessage.Data(data1), XPCMessage.Data(data2))
        bytes.removeLast()
        let data3 = NSData(bytes: &bytes, length: bytes.count)
        XCTAssertNotEqual(XPCMessage.Data(data1), XPCMessage.Data(data3))
    }
    
    func testDateMarshalling() {
        let date = NSDate(timeIntervalSince1970: 10)
        switch toAndFromXPCMessage(XPCMessage.Date(date)) {
        case .Date(let resultDate):
            XCTAssertEqual(resultDate, date)
        default:
            XCTFail("Expected date value")
        }
    }
    
    func testDateEquality() {
        let date1 = NSDate(timeIntervalSince1970: 10)
        let date2 = NSDate(timeIntervalSince1970: 10)
        XCTAssertEqual(XPCMessage.Date(date1), XPCMessage.Date(date2))
        XCTAssertNotEqual(XPCMessage.Date(date1), XPCMessage.Date(date1.dateByAddingTimeInterval(1)))
    }
    
    func testDictionaryMarshalling() {
        let dict: [String: Int64] = ["A": 1, "B": 2, "C": 3]
        var xpcDict = [String: XPCMessage]()
        for (key, value) in dict {
            xpcDict[key] = XPCMessage.Int64(value)
        }
        print(xpcDict)
        switch toAndFromXPCMessage(XPCMessage.Dictionary(xpcDict)) {
        case .Dictionary(let d):
            print(d)
            var resultDict = [String: Int64]()
            for (key, value) in d {
                switch value {
                case .Int64(let intValue):
                    resultDict[key] = intValue
                default:
                    XCTFail("Expected inner object to be Int64 value")
                }
            }
            XCTAssertEqual(resultDict, dict)
        default:
            XCTFail("Expected dictionary value")
        }
    }
    
    func testDictionaryEquality() {
        var dict = [
            "A": XPCMessage.Int64(1),
            "B": XPCMessage.Int64(2),
            "C": XPCMessage.Int64(3)
        ]
        let xpcDict = XPCMessage.Dictionary(dict)
        XCTAssertEqual(xpcDict, xpcDict)
        dict.removeValueForKey("A")
        XCTAssertNotEqual(xpcDict, XPCMessage.Dictionary(dict))
    }
    
    func testDoubleMarshalling() {
        let value = M_PI
        switch toAndFromXPCMessage(XPCMessage.Double(value)) {
        case .Double(let resultValue):
            XCTAssertEqual(resultValue, value)
        default:
            XCTFail("Expected double value")
        }
    }
    
    func testDoubleEquality() {
        let xpcPi = XPCMessage.Double(M_PI)
        XCTAssertEqual(xpcPi, xpcPi)
        XCTAssertNotEqual(xpcPi, XPCMessage.Double(M_PI_2))
    }
    
    private func createScratchFile(name: String = "XPCMessageTests") -> String {
        let path = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(name)
        NSData().writeToFile(path, atomically: true)
        return path
    }
    
    func testFileHandleMarshalling() {
        let fileHandle = NSFileHandle(forWritingAtPath: createScratchFile())!
        defer {
            fileHandle.closeFile()
        }
        var fhStat = stat()
        if (fstat(fileHandle.fileDescriptor, &fhStat) < 0) {
            XCTFail("Failed to get file status")
        } else {
            switch toAndFromXPCMessage(XPCMessage.FileHandle(fileHandle)) {
            case .FileHandle(let resultFileHandle):
                var resultFhStat = stat()
                if (fstat(resultFileHandle.fileDescriptor, &resultFhStat) < 0) {
                    XCTFail("Failed to get file status")
                } else {
                    XCTAssertEqual(fhStat.st_dev, resultFhStat.st_dev)
                    XCTAssertEqual(fhStat.st_ino, resultFhStat.st_ino)
                }
            default:
                XCTFail("Expected file handle value")
            }
        }
    }
    
    func testFileHandleEquality() {
        let path = createScratchFile()
        let fh1 = NSFileHandle(forWritingAtPath: path)!
        let fh2 = NSFileHandle(forWritingAtPath: path)!
        let fh3 = NSFileHandle(forWritingAtPath: createScratchFile("XPCMessageTests2"))!
        defer {
            fh1.closeFile()
            fh2.closeFile()
            fh3.closeFile()
        }
        XCTAssertEqual(XPCMessage.FileHandle(fh1), XPCMessage.FileHandle(fh2))
        XCTAssertNotEqual(XPCMessage.FileHandle(fh1), XPCMessage.FileHandle(fh3))
    }
    
    func testInt64Marshalling() {
        let value = -10 as Int64
        switch toAndFromXPCMessage(XPCMessage.Int64(value)) {
        case .Int64(let resultValue):
            XCTAssertEqual(resultValue, value)
        default:
            XCTFail("Expected Int64 value")
        }
    }
    
    func testInt64Equality() {
        let xpcInt = XPCMessage.Int64(-10)
        XCTAssertEqual(xpcInt, xpcInt)
        XCTAssertNotEqual(xpcInt, XPCMessage.Int64(1))
    }
    
    func testNullMarshalling() {
        switch toAndFromXPCMessage(XPCMessage.Null) {
        case .Null: break
        default:
            XCTFail("Expected null value")
        }
    }
    
    func testNullEquality() {
        let xpcNull = XPCMessage.Null
        XCTAssertEqual(xpcNull, xpcNull)
        XCTAssertNotEqual(xpcNull, XPCMessage.Int64(10))
    }
    
    func testStringMarshalling() {
        let str = "Hello World"
        switch toAndFromXPCMessage(XPCMessage.String(str)) {
        case .String(let resultStr):
            XCTAssertEqual(resultStr, str)
        default:
            XCTFail("Expected string value")
        }
    }
    
    func testStringEquality() {
        let xpcString = XPCMessage.String("Hello World")
        XCTAssertEqual(xpcString, xpcString)
        XCTAssertNotEqual(xpcString, XPCMessage.String("Foo"))
    }
    
    func testUInt64Marshalling() {
        let value = 25 as UInt64
        switch toAndFromXPCMessage(XPCMessage.UInt64(value)) {
        case .UInt64(let resultValue):
            XCTAssertEqual(resultValue, value)
        default:
            XCTFail("Expected UInt64 value")
        }
    }
    
    func testUInt64Equality() {
        let xpcUInt = XPCMessage.UInt64(25)
        XCTAssertEqual(xpcUInt, xpcUInt)
        XCTAssertNotEqual(xpcUInt, XPCMessage.UInt64(1))
    }
    
    func testUUIDMarshalling() {
        let UUID = NSUUID()
        switch toAndFromXPCMessage(XPCMessage.UUID(UUID)) {
        case .UUID(let resultUUID):
            XCTAssertEqual(resultUUID, UUID)
        default:
            XCTFail("Expected UUID value")
        }
    }
    
    func testUUIDEquality() {
        let xpcUUID = XPCMessage.UUID(NSUUID())
        XCTAssertEqual(xpcUUID, xpcUUID)
        XCTAssertNotEqual(xpcUUID, XPCMessage.UUID(NSUUID()))
    }
}
