import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    router.on(.GET, at: ["hello", "world"]) { req in
        return "Hello, world!"
    }
    
    // MARK: - 配置Controller
    let acronymsController = AcronymsController()
    try router.register(collection: acronymsController)
    
    let usersController = UsersController()
    try router.register(collection: usersController)
    
    let categoriesController = CategoriesController()
    try router.register(collection: categoriesController)
    
    let websiteController = WebsiteController()
    try router.register(collection: websiteController)
}
