import FluentSQLite
import Vapor


/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentSQLiteProvider())

    /// Create a application controller service that handle the sochet channel
    let wsAppsController = ApplicationController()
    services.register(wsAppsController)
    
    ///register websocket channel
    let wsChannel = NIOWebSocketServer.default()
    wsChannel.get("applications", use: wsAppsController.ConnectSessionTo)
    wsChannel.get("applications", String.parameter, use: wsAppsController.ReConnectTo)
    wsChannel.get("applications/clone/", String.parameter, use: wsAppsController.CloneTo)
    services.register(wsChannel, as: WebSocketServer.self)
    
    
    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    
    
    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .memory)

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)

    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Todo.self, database: .sqlite)
    services.register(migrations)
}
