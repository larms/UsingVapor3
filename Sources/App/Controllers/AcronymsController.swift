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

    }
    
    /// 获取所有的Acronym    /api/acronyms        GET
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    /// 创建一个Acronym     /api/acronyms        POST
    func createHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.content.decode(Acronym.self).flatMap(to: Acronym.self, { acronym in
            return acronym.save(on: req)
        })
    }
    
    //// 获取某个Acronym    /api/acronyms/2      GET
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }
    
    /// 更新数据 /api/acronyms/2     PUT
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self), req.content.decode(Acronym.self), { acronym, updatedAcronym in
            acronym.short = updatedAcronym.short
            acronym.long = updatedAcronym.long
            
            return acronym.save(on: req)
        })
    }
    
    /// 删除某个Acronym /api/acronyms/3     DELETE
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Acronym.self).delete(on: req).transform(to: HTTPStatus.noContent)
    }
    
    /// 搜索结果     /api/acronyms/search?term=WTF
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
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
    func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
        return Acronym.query(on: req).first().map(to: Acronym.self, {  acronym in
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }
            return acronym
        })
    }
    
    /// 升序排序
    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try Acronym.query(on: req).sort(\.short, QuerySortDirection.ascending).all()
    }
}
