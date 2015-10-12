//  Copyright © 2015 Indragie Karunaratne. All rights reserved.

import XCTest
import ReactiveXPC

class XPCValueTests: XCTestCase {
    private func toAndFromXPCValue(object: XPCValue) -> XPCValue {
         return XPCValue(object.toDarwinXPCObject())!
    }
    
    func testArrayMarshalling() {
        let numbers: [Int64] = [1, 2, 3]
        let numbersXPC = numbers.map { XPCValue.Int64($0) }
        switch toAndFromXPCValue(XPCValue.Array(numbersXPC)) {
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
        let numbers = [1, 2, 3].map { XPCValue.Int64($0) }
        let xpcNumbers = XPCValue.Array(numbers)
        XCTAssertEqual(xpcNumbers, xpcNumbers)
        let differentNumbers = [4, 5, 6].map { XPCValue.Int64($0) }
        XCTAssertNotEqual(xpcNumbers, XPCValue.Array(differentNumbers))
    }
    
    func testBooleanMarshalling() {
        let value = true
        switch toAndFromXPCValue(XPCValue.Boolean(value)) {
        case .Boolean(let resultValue):
            XCTAssertEqual(resultValue, value)
        default:
            XCTFail("Expect boolean value")
        }
    }
    
    func testBooleanEquality() {
        let xpcTrue = XPCValue.Boolean(true)
        XCTAssertEqual(xpcTrue, xpcTrue)
        XCTAssertNotEqual(xpcTrue, XPCValue.Boolean(false))
    }
    
    func testDataMarshalling() {
        var bytes = [0xDE, 0xAD, 0xBE, 0xEF] as [UInt8]
        let data = NSData(bytes: &bytes, length: bytes.count)
        switch toAndFromXPCValue(XPCValue.Data(data)) {
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
        XCTAssertEqual(XPCValue.Data(data1), XPCValue.Data(data2))
        bytes.removeLast()
        let data3 = NSData(bytes: &bytes, length: bytes.count)
        XCTAssertNotEqual(XPCValue.Data(data1), XPCValue.Data(data3))
    }
    
    func testDateMarshalling() {
        let date = NSDate(timeIntervalSince1970: 10)
        switch toAndFromXPCValue(XPCValue.Date(date)) {
        case .Date(let resultDate):
            XCTAssertEqual(resultDate, date)
        default:
            XCTFail("Expected date value")
        }
    }
    
    func testDateEquality() {
        let date1 = NSDate(timeIntervalSince1970: 10)
        let date2 = NSDate(timeIntervalSince1970: 10)
        XCTAssertEqual(XPCValue.Date(date1), XPCValue.Date(date2))
        XCTAssertNotEqual(XPCValue.Date(date1), XPCValue.Date(date1.dateByAddingTimeInterval(1)))
    }
    
    func testDictionaryMarshalling() {
        let dict: [String: Int64] = ["A": 1, "B": 2, "C": 3]
        var xpcDict = [String: XPCValue]()
        for (key, value) in dict {
            xpcDict[key] = XPCValue.Int64(value)
        }
        print(xpcDict)
        switch toAndFromXPCValue(XPCValue.Dictionary(xpcDict)) {
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
            "A": XPCValue.Int64(1),
            "B": XPCValue.Int64(2),
            "C": XPCValue.Int64(3)
        ]
        let xpcDict = XPCValue.Dictionary(dict)
        XCTAssertEqual(xpcDict, xpcDict)
        dict.removeValueForKey("A")
        XCTAssertNotEqual(xpcDict, XPCValue.Dictionary(dict))
    }
    
    func testDoubleMarshalling() {
        let value = M_PI
        switch toAndFromXPCValue(XPCValue.Double(value)) {
        case .Double(let resultValue):
            XCTAssertEqual(resultValue, value)
        default:
            XCTFail("Expected double value")
        }
    }
    
    func testDoubleEquality() {
        let xpcPi = XPCValue.Double(M_PI)
        XCTAssertEqual(xpcPi, xpcPi)
        XCTAssertNotEqual(xpcPi, XPCValue.Double(M_PI_2))
    }
    
    private func createScratchFile(name: String = "XPCValueTests") -> String {
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
            switch toAndFromXPCValue(XPCValue.FileHandle(fileHandle)) {
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
        let fh3 = NSFileHandle(forWritingAtPath: createScratchFile("XPCValueTests2"))!
        defer {
            fh1.closeFile()
            fh2.closeFile()
            fh3.closeFile()
        }
        XCTAssertEqual(XPCValue.FileHandle(fh1), XPCValue.FileHandle(fh2))
        XCTAssertNotEqual(XPCValue.FileHandle(fh1), XPCValue.FileHandle(fh3))
    }
    
    func testInt64Marshalling() {
        let value = -10 as Int64
        switch toAndFromXPCValue(XPCValue.Int64(value)) {
        case .Int64(let resultValue):
            XCTAssertEqual(resultValue, value)
        default:
            XCTFail("Expected Int64 value")
        }
    }
    
    func testInt64Equality() {
        let xpcInt = XPCValue.Int64(-10)
        XCTAssertEqual(xpcInt, xpcInt)
        XCTAssertNotEqual(xpcInt, XPCValue.Int64(1))
    }
    
    func testNullMarshalling() {
        switch toAndFromXPCValue(XPCValue.Null) {
        case .Null: break
        default:
            XCTFail("Expected null value")
        }
    }
    
    func testNullEquality() {
        let xpcNull = XPCValue.Null
        XCTAssertEqual(xpcNull, xpcNull)
        XCTAssertNotEqual(xpcNull, XPCValue.Int64(10))
    }
    
    func testStringMarshalling() {
        let str = "Hello World"
        switch toAndFromXPCValue(XPCValue.String(str)) {
        case .String(let resultStr):
            XCTAssertEqual(resultStr, str)
        default:
            XCTFail("Expected string value")
        }
    }
    
    func testStringEquality() {
        let xpcString = XPCValue.String("Hello World")
        XCTAssertEqual(xpcString, xpcString)
        XCTAssertNotEqual(xpcString, XPCValue.String("Foo"))
    }
    
    func testUInt64Marshalling() {
        let value = 25 as UInt64
        switch toAndFromXPCValue(XPCValue.UInt64(value)) {
        case .UInt64(let resultValue):
            XCTAssertEqual(resultValue, value)
        default:
            XCTFail("Expected UInt64 value")
        }
    }
    
    func testUInt64Equality() {
        let xpcUInt = XPCValue.UInt64(25)
        XCTAssertEqual(xpcUInt, xpcUInt)
        XCTAssertNotEqual(xpcUInt, XPCValue.UInt64(1))
    }
    
    func testUUIDMarshalling() {
        let UUID = NSUUID()
        switch toAndFromXPCValue(XPCValue.UUID(UUID)) {
        case .UUID(let resultUUID):
            XCTAssertEqual(resultUUID, UUID)
        default:
            XCTFail("Expected UUID value")
        }
    }
    
    func testUUIDEquality() {
        let xpcUUID = XPCValue.UUID(NSUUID())
        XCTAssertEqual(xpcUUID, xpcUUID)
        XCTAssertNotEqual(xpcUUID, XPCValue.UUID(NSUUID()))
    }
}
