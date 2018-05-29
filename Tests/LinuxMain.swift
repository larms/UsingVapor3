// 导入包含所要测试的AppTests模块
import XCTest
@testable import AppTests

// 提供所有 XCTestCase 到 XCTMain(_:), 在Linux上测试时, 应用程序会执行这些操作
XCTMain([
    testCase(AcronymTests.allTests),
    testCase(CategoryTests.allTests),
    testCase(UserTests.allTests)
    ])
