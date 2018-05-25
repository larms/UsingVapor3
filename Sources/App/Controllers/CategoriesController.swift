import Vapor

struct CategoriesController: RouteCollection {
    func boot(router: Router) throws {
        let categoriesRouter = router.grouped("api", "categories")
        categoriesRouter.post(Category.self, use: createHandler)
        categoriesRouter.get(use: getAllHandler)
        categoriesRouter.get(Category.parameter, use: getHandler)
        
        categoriesRouter.get(Category.parameter, "acronyms", use: getAcronymsHandler)
    }
    
    /// 创建一个Category
    private func createHandler(_ req: Request, category: Category) throws -> Future<Category> {
        return category.save(on: req)
    }
    
    /// 查询所有Category
    private func getAllHandler(_ req: Request) throws -> Future<[Category]> {
        return Category.query(on: req).all()
    }
    
    /// 获取某个Category
    private func getHandler(_ req: Request) throws -> Future<Category> {
        return try req.parameters.next(Category.self)
    }
    
    /// 获取acronyms
    private func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req.parameters.next(Category.self).flatMap(to: [Acronym].self) { category in
            try category.acronyms.query(on: req).all()
        }
    }
 }
