import mist
import gleam/int
import gleam/result
import gleam/erlang/os
import rinhabe/database
import rinhabe/server/router

pub fn start(db: database.DB) {
    let assert Ok(_) = router.request_handler(db)
        |> mist.new()
        |> mist.port(get_port())
        |> mist.start_http()
    Nil
}

fn get_port() -> Int {
  os.get_env("API_PORT")
  |> result.then(int.parse)
  |> result.unwrap(3000)
}
