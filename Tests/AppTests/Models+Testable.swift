@testable import App
import FluentPostgreSQL

// MARK: - User
extension User {
    /// 根据提供的详细信息, 创建一个User并保存到数据库中
    ///
    /// - Parameters:
    ///   - name: name, 有默认值, 不关心则不必提供任何值
    ///   - username: username, 有默认值, 不关心则不必提供任何值
    ///   - connection: 数据库连接
    /// - Returns: 返回一个已创建并保存到数据库中的User
    static func create(name: String = "Luke", username: String = "lukes", on connection: PostgreSQLConnection) throws -> User {
        let user = User(name: name, username: username)
        return try user.save(on: connection).wait()
    }
}

// MARK: - Acronym
extension Acronym {
    /// 创建Acronym, 并将其保存在数据库中
    ///
    /// - Parameters:
    ///   - short: short, 有默认值, 不关心则不必提供任何值
    ///   - long: long, 有默认值, 不关心则不必提供任何值
    ///   - user: user, 如果不为此Acronym提供User, 则会创建一个默认用户
    ///   - connection: 数据库连接
    /// - Returns: 返回一个已创建并保存到数据库中的Acronym
    static func create(short: String = "OMV", long: String = "Oh My Vapor", user: User? = nil, on connection: PostgreSQLConnection) throws -> Acronym {
        var acronymsUser = user
        if acronymsUser == nil {
            acronymsUser = try User.create(on: connection)
        }
        
        let acronym = Acronym(short: short, long: long, userID: acronymsUser!.id!)
        
        return try acronym.save(on: connection).wait()
    }
}

// MARK: - App.Category
extension App.Category {
    /// 创建Category, 并将其保存在数据库中
    ///
    /// - Parameters:
    ///   - name: name, 有默认值, 不关心则不必提供任何值
    ///   - connection: 数据库连接
    /// - Returns: 返回一个已创建并保存到数据库中的Category
    static func create(name: String = "Random", on connection: PostgreSQLConnection) throws -> App.Category {
        let category = Category(name: name)
        return try category.save(on: connection).wait()
    }
}
