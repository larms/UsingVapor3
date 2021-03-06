import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        acronymsRoutes.get(use: getAllHandler)
        acronymsRoutes.post(use: createHandler)
        acronymsRoutes.get(Acronym.parameter, use: getHandler)
        acronymsRoutes.put(Acronym.parameter, use: updateHandler)
        acronymsRoutes.delete(Acronym.parameter, use: deleteHandler)
        acronymsRoutes.get("search", use: searchHandler)
        acronymsRoutes.get("first", use: getFirstHandler)
        acronymsRoutes.get("sorted", use: sortedHandler)
        
        /// /api/acronyms/<acronym.id>/user         GET
        acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
        
        /// /api/acronyms/<acronym.id>/categories/<category.id>     POST
        acronymsRoutes.post(Acronym.parameter, "categories", Category.parameter, use: addCategoriesHendler)
        /// /api/acronyms/<acronym.id>/categories
        acronymsRoutes.get(Acronym.parameter, "categories", use: getCategoriesHandler)
    }
    
    /// 获取所有的Acronym    /api/acronyms        GET
    private func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    /// 创建一个Acronym     /api/acronyms        POST
    private func createHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.content.decode(Acronym.self).flatMap(to: Acronym.self, { acronym in
            return acronym.save(on: req)
        })
    }
    
    //// 获取某个Acronym    /api/acronyms/2      GET
    private func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }
    
    /// 更新数据 /api/acronyms/2     PUT
    private func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self), req.content.decode(Acronym.self), { acronym, updatedAcronym in
            acronym.short = updatedAcronym.short
            acronym.long = updatedAcronym.long
            acronym.userID = updatedAcronym.userID
            
            return acronym.save(on: req)
        })
    }
    
    /// 删除某个Acronym /api/acronyms/3     DELETE
    private func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Acronym.self).delete(on: req).transform(to: HTTPStatus.noContent)
    }
    
    /// 搜索结果     /api/acronyms/search?term=WTF
    private func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        // 多个条件搜索结果   /api/acronyms/search?term=Oh%20My%20Vapor 或者 term=Oh+My+Vapor
         return try Acronym.query(on: req).group(.or) { or in
             try or.filter(\.short == searchTerm)
             try or.filter(\.long == searchTerm)
         }.all()
        
        // 单个条件搜索结果     /api/acronyms/search?term=OMV
        // return try Acronym.query(on: req).filter(\.short == searchTerm).all()
    }
    
    /// 获取第一个Acronym
    private func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
        return Acronym.query(on: req).first().map(to: Acronym.self, {  acronym in
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }
            return acronym
        })
    }
    
    /// 升序排序
    private func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try Acronym.query(on: req).sort(\.short, QuerySortDirection.ascending).all()
    }
    
    /// 获取与某个Acronym存在关系的User
    private func getUserHandler(_ req: Request) throws -> Future<User> {
        return try req.parameters.next(Acronym.self).flatMap(to: User.self, { acronym in
            try acronym.user.get(on: req)
        })
    }
    
    /// 实际创建两个模型之间的关系时, 需要使用pivot. 创建新的路径处理来建立acronym和category之间的关系
    ///
    /// - Parameter req: 请求
    /// - Returns: Future\<HTTPStatus\>
    private func addCategoriesHendler(_ req: Request) throws -> Future<HTTPStatus> {
        // 使用 flatMap(to:_:_:) 从请求的参数中取出 acronym 和 category
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self), req.parameters.next(Category.self)) { acronym, category in
            
            // 创建一个新的 AcronymCategoryPivot 对象, 使用 requireID() 以确保 ID 已经设置过, 如果没设置过将抛出错误
            let pivot = try AcronymCategoryPivot(acronym.requireID(), category.requireID())
            
            // 将 pivot 保存到数据库, 然后将结果转换为 201 Created 的响应
            // 201 Created: 请求已经被实现, 而且有一个新的资源已经依据请求的需要而建立, 且其 URI 已经随 Location 头信息返回. 假如需要的资源无法及时建立的话, 应当返回 '202 Accepted'.
            /* enum HTTPResponseStatus: HTTP响应状态码
                2xx
                case ok
                case created
                case accepted
                case nonAuthoritativeInformation
                case noContent
                case resetContent
                case partialContent
            */
            return pivot.save(on: req).transform(to: .created)
        }
    }
    
    /// 获取categories
    private func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters.next(Acronym.self).flatMap(to: [Category].self) { acronym in
            try acronym.categories.query(on: req).all()
        }
    }
}
