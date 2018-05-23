import Vapor

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRouter = router.grouped("api", "users")
        usersRouter.post(User.self, use: createHandler)
        usersRouter.get(use: getAllHandler)
        usersRouter.get(User.parameter, use: getHandler)
        
        /// /api/users/<user.id>/acronyms
        usersRouter.get(User.parameter, "acronyms", use: getAcronymsHandler)
    }
    
    /// 创建一个User
    private func createHandler(_ req: Request, user: User) throws -> Future<User> {
        return user.save(on: req)
    }
    
    /// 获取所有User
    private func getAllHandler(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
    
    /// 获取某个User
    private func getHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(User.self)
    }
    
    /// 获取与某个User存在关系的Acronym
    private func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req.parameters.next(User.self).flatMap(to: [Acronym].self) { user in
            try user.acronyms.query(on: req).all()
        }
    }
}
