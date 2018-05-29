import Vapor
import App
import FluentPostgreSQL

extension Application {
    /// 创建可测试的App对象. 比如像main.swift中那样, 这会创建一个完整的App对象, 但不会开始运行这个App.
    /// 这有助于确保在测试调用 App.configure(_:_:_:) 时正确配置实际的App. 注意: 这里要使用 Environment.testing
    ///
    /// - Parameter envArgs: 环境参数, 如果需要, 可以指定
    /// - Returns: 已创建的App
    static func testable(envArgs: [String]? = nil) throws -> Application {
        // 创建App, 比如像main.swift中那样, 这会创建一个完整的App对象, 但不会开始运行这个App
        // 这有助于确保在测试调用 App.configure(_:_:_:) 时正确配置实际的App. 注意: 这里要使用 Environment.testing
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        
        if let envArgs = envArgs {
            env.arguments = envArgs
        }
        
        try App.configure(&config, &env, &services)
        let app = try Application(config: config, environment: env, services: services)
        try App.boot(app)
        return app
    }
    
    /// 创建一个可以运行revert命令(重置数据库)的App
    static func reset() throws {
        let revertEnvArgs = ["vapor", "revert", "--all", "-y"]
        try Application.testable(envArgs: revertEnvArgs).asyncRun().wait()
    }
    
    /// 一个将请求发送到路径并返回响应的方法
    ///
    /// - Parameters:
    ///   - path: 请求路径
    ///   - method: HTTPMethod, .GET, .POST 等等
    ///   - headers: headers
    ///   - body: body
    /// - Returns: 响应
    func sendRequest(to path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), body: HTTPBody = .init()) throws -> Response {
        // 创建一个响应者类型, 这是对请求的响应
        let responder = try self.make(Responder.self)
        // 创建一个请求, 这是一个HTTPRequest, 所以有一个Worker来执行它
        let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers, body: body)
        // 由于这是测试, 这里可以打包请求来简化代码
        let wrappedRequest = Request(http: request, using: self)
        
        // 返回发送请求获得的响应
        return try responder.respond(to: wrappedRequest).wait()
    }
    
    /// 一个接受Decodable类型, 发送请求获取响应的通用方法
    ///
    /// - Parameters:
    ///   - path: 请求路径
    ///   - method: HTTPMethod, 默认 .GET
    ///   - headers: headers
    ///   - body: body
    ///   - type: 一个遵循Decodable的类型
    /// - Returns: 将响应数据解码为泛型类型的结果
    func getResponse<T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), body: HTTPBody = .init(), decodeTo type: T.Type) throws -> T where T: Decodable {
        // 通过上面定义的sendRequest()方法获取响应
        let response = try self.sendRequest(to: path, method: method, headers: headers, body: body)
        
        // 将响应数据解码为泛型类型并返回结果
        return try JSONDecoder().decode(type, from: response.http.body.data!)
    }
    
    /// 发送请求获取响应的通用方法
    ///
    /// - Parameters:
    ///   - path: 请求路径
    ///   - method: HTTPMethod, 默认 .GET
    ///   - headers: headers
    ///   - data: 数据
    ///   - type: 一个遵循Decodable的类型
    /// - Returns: 将响应数据解码为泛型类型的结果
    func getResponse<T, U>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), data: U, decodeTo type: T.Type) throws -> T where T: Decodable, U: Encodable {
        let body = try HTTPBody(data: JSONEncoder().encode(data))
        return try self.getResponse(to: path, method: method, headers: headers, body: body, decodeTo: type)
    }
    
    /// 一个发送请求与请求体到路径, 忽略响应的通用方法
    ///
    /// - Parameters:
    ///   - path: 请求路径
    ///   - method: HTTPMethod, .GET, .POST 等等
    ///   - headers: headers
    ///   - data: 数据
    func sendRequest<T>(to path: String, method: HTTPMethod, headers: HTTPHeaders, data: T) throws where T: Encodable {
        let body = try HTTPBody(data: JSONEncoder().encode(data))
        _ = try self.sendRequest(to: path, method: method, headers: headers, body: body)
    }
    
}
