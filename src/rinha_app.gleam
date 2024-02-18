import gleam/io
import gleam/erlang/process
import rinhabe/database
import rinhabe/server/runtime

pub fn main() {
  // connect to the database
  let db = database.connect()

  // initialize the web server
  io.println("Rinha Backend v2024")
  runtime.start(db)

  // wait for shutdown
  process.sleep_forever()
  database.disconnect(db)
}
