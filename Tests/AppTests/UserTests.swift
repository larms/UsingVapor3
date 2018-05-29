@testable import App
import XCTest
import Vapor
import FluentPostgreSQL

/// 用户相关的测试
final class UserTests: XCTestCase {
    
    let usersName = "Alice"
    let usersUsername = "alice"
    let usersURI = "/api/users/"
    var app: Application!
    var conn: PostgreSQLConnection!
    
    /// 重新setUp(), 设置每次运行测试之前必须执行的代码
    override func setUp() {
        // 重置数据库
        try! Application.reset()
        
        // 创建App
        app = try! Application.testable()
        
        // 创建'数据库连接'来执行数据库操作. 注意: 这里和整个测试中使用 .wait().
        // 由于不是在EventLoop上运行测试, 因此可以使用 .wait() 等待将来的返回. 这有助于简化代码.
        conn = try! app.newConnection(to: .psql).wait()
    }
    
    override func tearDown() {
        // 测试完成后, 关闭数据库连接
        conn.close()
    }
    
    /// 测试用户可以从API中检索
    func testUsersCanBeRetrievedFromAPI() throws {
        // 创建多个用户
        let user = try User.create(name: usersName, username: usersUsername, on: conn)
        _ = try User.create(on: conn)
        
        let users = try app.getResponse(to: usersURI, decodeTo: [User].self)
        
        // 确保响应中的User数量正确, 并且测试用户与开始所创建的用户相匹配
        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].name, usersName)
        XCTAssertEqual(users[0].username, usersUsername)
        XCTAssertEqual(users[0].id, user.id)
    }
    
    // 测试以通过API保存用户
    func testUserCanBeSavedWithAPI() throws {
        let user = User(name: usersName, username: usersUsername)
        // 发送POST请求到API并得到响应, 使用 user 对象作为请求体, 并正确设置请求头来模拟 JSON 请求, 将响应转换为 User 对象
        let receivedUser = try app.getResponse(to: usersURI, method: .POST, headers: ["Content-Type": "application/json"], data: user, decodeTo: User.self)
        
        // 断言API的响应的用户与开始所创建的用户相匹配
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertNotNil(receivedUser.id)
        
        // 获取所有的User
        let users = try app.getResponse(to: usersURI, decodeTo: [User].self)
        
        // 确保响应只包含在第一个请求中创建的用户
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users[0].name, usersName)
        XCTAssertEqual(users[0].username, usersUsername)
        XCTAssertEqual(users[0].id, receivedUser.id)
    }
    
    func testGettingASingleUserFromTheAPI() throws {
        let user = try User.create(name: usersName, username: usersUsername, on: conn)
        
        // 从 /api/users/<user.id> 获取user
        let receivedUser = try app.getResponse(to: "\(usersURI)\(user.id!)", decodeTo: User.self)
        
        // 断言测试响应的用户与开始所创建的用户相匹配
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertEqual(receivedUser.id, user.id)
    }
    
    func testGettingAUsersAcronymsFromTheAPI() throws {
        // 为Acronym创建用户
        let user = try User.create(on: conn)
        
        // 定义Acronym
        let acronymShort = "OMG"
        let acronymLong = "Oh My God"
        let acronym = try Acronym.create(short: acronymShort, long: acronymLong, user: user, on: conn)
        _ = try Acronym.create(short: "TIL", long: "Today I Learned", user: user, on: conn)
        
        // 从 /api/users/<user.id>/acronyms 获取 user 所有的Acronym
        let acronyms = try app.getResponse(to: "\(usersURI)\(user.id!)/acronyms", decodeTo: [Acronym].self)
        
        // 确保响应中的Acronym数量正确, 并且测试第一个Acronym与开始所创建的Acronym相匹配
        XCTAssertEqual(acronyms.count, 2)
        XCTAssertEqual(acronyms[0].id, acronym.id)
        XCTAssertEqual(acronyms[0].short, acronym.short)
        XCTAssertEqual(acronyms[0].long, acronym.long)
    }
    
    static let allTests = [
        ("testUsersCanBeRetrievedFromAPI", testUsersCanBeRetrievedFromAPI),
        ("testUserCanBeSavedWithAPI", testUserCanBeSavedWithAPI),
        ("testGettingASingleUserFromTheAPI", testGettingASingleUserFromTheAPI),
        ("testGettingAUsersAcronymsFromTheAPI", testGettingAUsersAcronymsFromTheAPI),
        ]

}
