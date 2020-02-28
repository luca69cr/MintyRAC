import FluentSQLite
import Vapor
import Redis


///Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    
    
    
    
    ///**Register providers first**
    ///
    ///for default NIO use max worker count as a number of core
    ///the defalut max connection on redis is 10.000 so the max number of RAC Servever is 10
    ///increase the number of redis max connection
    let serverConfig = NIOServerConfig.default(workerCount: 1000)
    services.register(serverConfig)
    
    try services.register(FluentSQLiteProvider())
    try services.register(RedisProvider())

    ///**Create a application controller service that handle the sochet channel**
    let wsAppsController = ApplicationController()
    services.register(wsAppsController)
    
    ///**register websocket channel**
    let wsChannel = NIOWebSocketServer.default()
    wsChannel.get("applications", use: wsAppsController.ConnectSessionTo)
    wsChannel.get("applications", String.parameter, use: wsAppsController.ReConnectTo)
    wsChannel.get("applications/clone/", String.parameter, use: wsAppsController.CloneTo)
    services.register(wsChannel, as: WebSocketServer.self)
    
    ///**Register routes to the router**
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    ///** Register middleware**
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    ///**Create databases config**
    var databases = DatabasesConfig()
    
    ///**Configure and Add a SQLite database**
    let sqlite = try SQLiteDatabase(storage: .memory)
    databases.add(database: sqlite, as: .sqlite)
    
    ///**configure Redis and add database**
    var redisConfig = RedisClientConfig()
    redisConfig.hostname = "localhost"
    /// The Redis server's port.
    redisConfig.port = 7001
    /// The Redis server's optional password.
    redisConfig.password = "password123"
    /// The database to connect to automatically.
    /// If nil, the connection will use the default 0.
    redisConfig.database=nil
    
    let redisDatabase = try RedisDatabase(config: redisConfig)
    databases.add(database: redisDatabase, as: .redis)
  
    ///**Register all databse**
    services.register(databases)

    ///**Configure migrations**
    var migrations = MigrationConfig()
    migrations.add(model: Todo.self, database: .sqlite)
    services.register(migrations)
}
