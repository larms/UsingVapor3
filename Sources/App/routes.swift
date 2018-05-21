import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    // /api/acronyms        POST
    router.post("api", "acronyms") { req -> Future<Acronym> in
        return try req.content.decode(Acronym.self).flatMap(to: Acronym.self, { acronym in
            return acronym.save(on: req)
        })
    }
    
    // /api/acronyms        GET
    router.get("api", "acronyms") { req -> Future<[Acronym]> in
        return Acronym.query(on: req).all()
    }
    
    // /api/acronyms/2      GET
    router.get("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return try req.parameters.next(Acronym.self)
    }
    
    // 更新数据 /api/acronyms/2     PUT
    router.put("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
        return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self), req.content.decode(Acronym.self), { acronym, updatedAcronym in
            acronym.short = updatedAcronym.short
            acronym.long = updatedAcronym.long
            
            return acronym.save(on: req)
        })
    }
    
    // 删除 /api/acronyms/3     DELETE
    router.delete("api", "acronyms", Acronym.parameter) { req -> Future<HTTPStatus> in
        return try req.parameters.next(Acronym.self).delete(on: req).transform(to: HTTPStatus.noContent)
    }
    
    // 搜索结果     /api/acronyms/search?term=WTF
    router.get("api", "acronyms", "search") { req -> Future<[Acronym]> in
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return try Acronym.query(on: req).filter(\.short == searchTerm).all()
        
        // 多个条件搜索结果   /api/acronyms/search?term=Oh%20My%20Vapor 或者 term=Oh+My+Vapor
        /*
        return try Acronym.query(on: req).group(.or) { or in
            try or.filter(\.short == searchTerm)
            try or.filter(\.long == searchTerm)
        }.all()
        */
    }
    
    // 第一个结果
    router.get("api", "acronyms", "first") { req -> Future<Acronym> in
        return Acronym.query(on: req).first().map(to: Acronym.self, {  acronym in
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }
            return acronym
        })
    }
    
    // 升序排序
    router.get("api", "acronyms", "sorted") { req -> Future<[Acronym]> in
        return try Acronym.query(on: req).sort(\.short, QuerySortDirection.ascending).all()
    }
}
