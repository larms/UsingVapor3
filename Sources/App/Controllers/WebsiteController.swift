import Vapor
import Leaf

struct WebsiteController: RouteCollection {
    // 实现 boot(router:)
    func boot(router: Router) throws {
        // 注册 indexHandler(_:) 处理根路径的GET请求. 即对 /. 的请求
        router.get(use: indexHandler)
        // /acronyms/<acronym.id>
        router.get("acronyms", Acronym.parameter, use: acronymHandler)
        // /users/<user.id>
        router.get("users", User.parameter, use: userHandler)
        router.get("users", use: allUsersHandler)
    }
    
    // 实现 indexHandler(_:), 返回的是 Future<View>
    private func indexHandler(_ req: Request) throws -> Future<View> {
        // 使用Fluent查询从数据库中获取所有Acronym
        return Acronym.query(on: req).all().flatMap(to: View.self, { acronyms in
            // 如果有的话，将其添加到 IndexContext 中, 否则设置为nil
            let acronymsData = acronyms.isEmpty ? nil : acronyms
            
            // context 的 title 将会替换 index.leaf 中的 #(title), 命名相同才能替换
            let context = IndexContext(title: "Homepage", acronyms: acronymsData)
            
            // 渲染index模板并返回结果
            // Leaf根据Resources/Views目录中的index.leaf模板文件生成一个页面. 注意: 调用 render(_:_:) 不需要文件扩展名".leaf"
            // 将 context 传递给 Leaf 作为 render(_:_:) 的第二个参数
            return try req.view().render("index", context)
        })
    }
    
    private func acronymHandler(_ req: Request) throws -> Future<View> {
        // 从请求的参数中提取acronym并打开结果
        return try req.parameters.next(Acronym.self).flatMap(to: View.self) { acronym in
            // 从acronym获取其user并打开结果
            return try acronym.user.get(on: req).flatMap(to: View.self) { user in
                // 创建AcronymContext, 并使用acronym.leaf模板呈现页面
                let context = AcronymContext(title: acronym.short, acronym: acronym, user: user)
                return try req.view().render("acronym", context)
            }
        }
    }
    
    private func userHandler(_ req: Request) throws -> Future<View> {
        // 从请求的参数中提取user并打开结果
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
            // 获取user的acronyms
            return try user.acronyms.query(on: req).all().flatMap(to: View.self) { acronyms in
                // 创建UserContext并使用user.leaf模板呈现页面, 这里不用考虑acronyms是否为nil, 因为在user.leaf中已做判断
                let context = UserContext(title: user.name, user: user, acronyms: acronyms)
                return try req.view().render("user", context)
            }
        }
    }
    
    private func allUsersHandler(_ req: Request) throws -> Future<View> {
        // 2
        return User.query(on: req).all().flatMap(to: View.self) { users in
            // 3
            let context = AllUsersContext(title: "All Users", users: users)
            return try req.view().render("allUsers", context)
        }
    }
}

struct IndexContext: Encodable {
    let title: String
    let acronyms: [Acronym]?
}

struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
}

struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}
