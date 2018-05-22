import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    // MARK: - 配置Controller
    let acronymsController = AcronymsController()
    try router.register(collection: acronymsController)
}
