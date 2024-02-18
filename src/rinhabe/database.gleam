import gleam/int
import gleam/pgo
import gleam/result
import gleam/dynamic
import gleam/erlang/os
import gleam/option.{Some}

pub type DB = pgo.Connection

pub fn connect() -> DB {
    pgo.Config(
        ..pgo.default_config(),
        host: get_host(),
        user: "admin",
        database: "rinha",
        password: Some("123"),
        pool_size: get_pool_size(),
    ) |> pgo.connect()
}

pub fn check_connection(db: DB) -> Result(Bool, Nil) {
    let sql_test = "SELECT id, saldo FROM contas LIMIT 1"
    let return_type = dynamic.tuple2(dynamic.int, dynamic.int)
    let assert Ok(response) = pgo.execute(sql_test, db, [], return_type)
    case response {
        response if response.count > 0 -> Ok(True)
        _ -> Error(Nil)
    }
}

pub fn disconnect(db: DB) {
    pgo.disconnect(db)
}

fn get_host() -> String {
    result.unwrap(os.get_env("DB_HOST"), "localhost")
}

fn get_pool_size() -> Int {
    os.get_env("DB_POOL")
        |> result.then(int.parse)
        |> result.unwrap(30)
}