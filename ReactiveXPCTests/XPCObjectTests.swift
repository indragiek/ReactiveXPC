//
//  XPCObjectTests.swift
//  ReactiveXPC
//
//  Created by Indragie on 10/9/15.
//  Copyright © 2015 Indragie Karunaratne. All rights reserved.
//

import XCTest
import ReactiveXPC

class XPCObjectTests: XCTestCase {
    private func toAndFromXPCObject(object: XPCObject) -> XPCObject {
         return XPCObject(xpcObject: object.toXPCObject())!
    }
    
    func testArrayMarshalling() {
        let numbers: [Int64] = [1, 2, 3]
        let numbersXPC = numbers.map { XPCObject.Int64($0) }
        switch toAndFromXPCObject(XPCObject.Array(numbersXPC)) {
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
        let numbers = [1, 2, 3].map { XPCObject.Int64($0) }
        let xpcNumbers = XPCObject.Array(numbers)
        XCTAssertEqual(xpcNumbers, xpcNumbers)
        let differentNumbers = [4, 5, 6].map { XPCObject.Int64($0) }
        XCTAssertNotEqual(xpcNumbers, XPCObject.Array(differentNumbers))
    }
    
    func testBooleanMarshalling() {
        let value = true
        switch toAndFromXPCObject(XPCObject.Boolean(value)) {
        case .Boolean(let resultValue):
            XCTAssertEqual(resultValue, value)
        default:
            XCTFail("Expect boolean value")
        }
    }
    
    func testBooleanEquality() {
        let xpcTrue = XPCObject.Boolean(true)
        XCTAssertEqual(xpcTrue, xpcTrue)
        XCTAssertNotEqual(xpcTrue, XPCObject.Boolean(false))
    }
    
    func testDataMarshalling() {
        var bytes = [0xDE, 0xAD, 0xBE, 0xEF] as [UInt8]
        let data = NSData(bytes: &bytes, length: bytes.count)
        switch toAndFromXPCObject(XPCObject.Data(data)) {
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
        XCTAssertEqual(XPCObject.Data(data1), XPCObject.Data(data2))
        bytes.removeLast()
        let data3 = NSData(bytes: &bytes, length: bytes.count)
        XCTAssertNotEqual(XPCObject.Data(data1), XPCObject.Data(data3))
    }
    
    func testDateMarshalling() {
        let date = NSDate(timeIntervalSince1970: 10)
        switch toAndFromXPCObject(XPCObject.Date(date)) {
        case .Date(let resultDate):
            XCTAssertEqual(resultDate, date)
        default:
            XCTFail("Expected date value")
        }
    }
    
    func testDateEquality() {
        let date1 = NSDate(timeIntervalSince1970: 10)
        let date2 = NSDate(timeIntervalSince1970: 10)
        XCTAssertEqual(XPCObject.Date(date1), XPCObject.Date(date2))
        XCTAssertNotEqual(XPCObject.Date(date1), XPCObject.Date(date1.dateByAddingTimeInterval(1)))
    }
    
    func testDictionaryMarshalling() {
        let dict: [String: Int64] = ["A": 1, "B": 2, "C": 3]
        var xpcDict = [String: XPCObject]()
        for (key, value) in dict {
            xpcDict[key] = XPCObject.Int64(value)
        }
        print(xpcDict)
        switch toAndFromXPCObject(XPCObject.Dictionary(xpcDict)) {
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
            "A": XPCObject.Int64(1),
            "B": XPCObject.Int64(2),
            "C": XPCObject.Int64(3)
        ]
        let xpcDict = XPCObject.Dictionary(dict)
        XCTAssertEqual(xpcDict, xpcDict)
        dict.removeValueForKey("A")
        XCTAssertNotEqual(xpcDict, XPCObject.Dictionary(dict))
    }
    
    func testDoubleMarshalling() {
        let value = M_PI
        switch toAndFromXPCObject(XPCObject.Double(value)) {
        case .Double(let resultValue):
            XCTAssertEqual(resultValue, value)
        default:
            XCTFail("Expected double value")
        }
    }
    
    func testDoubleEquality() {
        let xpcPi = XPCObject.Double(M_PI)
        XCTAssertEqual(xpcPi, xpcPi)
        XCTAssertNotEqual(xpcPi, XPCObject.Double(M_PI_2))
    }
    
    private func createScratchFile(name: String = "XPCObjectTests") -> String {
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
            switch toAndFromXPCObject(XPCObject.FileHandle(fileHandle)) {
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
        let fh3 = NSFileHandle(forWritingAtPath: createScratchFile("XPCObjectTests2"))!
        defer {
            fh1.closeFile()
            fh2.closeFile()
            fh3.closeFile()
        }
        XCTAssertEqual(XPCObject.FileHandle(fh1), XPCObject.FileHandle(fh2))
        XCTAssertNotEqual(XPCObject.FileHandle(fh1), XPCObject.FileHandle(fh3))
    }
    
    func testInt64Marshalling() {
        let value = -10 as Int64
        switch toAndFromXPCObject(XPCObject.Int64(value)) {
        case .Int64(let resultValue):
            XCTAssertEqual(resultValue, value)
        default:
            XCTFail("Expected Int64 value")
        }
    }
    
    func testInt64Equality() {
        let xpcInt = XPCObject.Int64(-10)
        XCTAssertEqual(xpcInt, xpcInt)
        XCTAssertNotEqual(xpcInt, XPCObject.Int64(1))
    }
    
    func testNullMarshalling() {
        switch toAndFromXPCObject(XPCObject.Null) {
        case .Null: break
        default:
            XCTFail("Expected null value")
        }
    }
    
    func testNullEquality() {
        let xpcNull = XPCObject.Null
        XCTAssertEqual(xpcNull, xpcNull)
        XCTAssertNotEqual(xpcNull, XPCObject.Int64(10))
    }
    
    func testStringMarshalling() {
        let str = "Hello World"
        switch toAndFromXPCObject(XPCObject.String(str)) {
        case .String(let resultStr):
            XCTAssertEqual(resultStr, str)
        default:
            XCTFail("Expected string value")
        }
    }
    
    func testStringEquality() {
        let xpcString = XPCObject.String("Hello World")
        XCTAssertEqual(xpcString, xpcString)
        XCTAssertNotEqual(xpcString, XPCObject.String("Foo"))
    }
    
    func testUInt64Marshalling() {
        let value = 25 as UInt64
        switch toAndFromXPCObject(XPCObject.UInt64(value)) {
        case .UInt64(let resultValue):
            XCTAssertEqual(resultValue, value)
        default:
            XCTFail("Expected UInt64 value")
        }
    }
    
    func testUInt64Equality() {
        let xpcUInt = XPCObject.UInt64(25)
        XCTAssertEqual(xpcUInt, xpcUInt)
        XCTAssertNotEqual(xpcUInt, XPCObject.UInt64(1))
    }
    
    func testUUIDMarshalling() {
        let UUID = NSUUID()
        switch toAndFromXPCObject(XPCObject.UUID(UUID)) {
        case .UUID(let resultUUID):
            XCTAssertEqual(resultUUID, UUID)
        default:
            XCTFail("Expected UUID value")
        }
    }
    
    func testUUIDEquality() {
        let xpcUUID = XPCObject.UUID(NSUUID())
        XCTAssertEqual(xpcUUID, xpcUUID)
        XCTAssertNotEqual(xpcUUID, XPCObject.UUID(NSUUID()))
    }
}
