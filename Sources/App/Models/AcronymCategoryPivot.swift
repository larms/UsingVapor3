// pivot(枢轴)是Fluent中包含关系的另一个模型类型.
// AcronymCategoryPivot将包含枢轴模型来管理兄弟关系。

import Foundation
import FluentPostgreSQL

/// 定义一个遵循PostgreSQLUUIDPivot的对象AcronymCategoryPivo, PostgreSQLUUIDPivot是一个Fluent的Pivot协议之上的辅助协议
final class AcronymCategoryPivot: PostgreSQLUUIDPivot {
    var id: UUID?
    
    // 定义2个属性链接到 Acronym.ID 和 Category.ID, 这是保持这种关系的原因
    var acronymID: Acronym.ID
    var categoryID: Category.ID
    
    typealias Left = Acronym
    typealias Right = Category
    
    static let leftIDKey: LeftIDKey = \.acronymID
    static let rightIDKey: RightIDKey = \.categoryID
    
    init(_ acronymID: Acronym.ID, _ categoryID: Category.ID) {
        self.acronymID = acronymID
        self.categoryID = categoryID
    }
}

// MARK: - Migration
extension AcronymCategoryPivot: Migration {
    /// 重写默认实现
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        // 在数据库中创建 AcronymCategoryPivot 表
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            // 在 AcronymCategoryPivot 的 acronymID 和 Acronym 的 id 之间添加引用, 这样就设置了外键(foreign key)的约束
            try builder.addReference(from: \.acronymID, to: \Acronym.id)
            try builder.addReference(from: \.categoryID, to: \Category.id)
        }
    }
}
