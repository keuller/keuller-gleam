import gleam/json
import gleam/bytes_builder
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import mist.{type Connection, type ResponseData}
import rinhabe/database

pub type Context {
    Context(db: database.DB, req: Request(Connection))
}

pub fn health_check(ctx: Context) -> Response(ResponseData) {
    case database.check_connection(ctx.db) {
        Ok(_) -> send(response.new(200), "OK")
        Error(Nil) -> send(response.new(400), "NOK")
    }
}

pub fn default_response() -> Response(ResponseData) {
    send(response.new(200), "Rinha Backend 2024")
}

pub fn not_found(ctx: Context, msg: String) -> Response(ResponseData) {
    case msg {
        "" -> send(response.new(404), "Resource not found '" <> ctx.req.path <> "'")
        _ -> send(response.new(404), msg)
    }
}

pub fn unprocessable_entity(msg: String) -> Response(ResponseData) {
    send(response.new(422), msg)
}

pub fn bad_request() -> Response(ResponseData) {
    send(response.new(400), "Bad request")
}

pub fn internal_server_error() -> Response(ResponseData) {
    send(response.new(500), "Internal server error")
}

pub fn send_json(result: json.Json) -> Response(ResponseData) {
    response.new(200)
    |> response.prepend_header("Content-Type", "application/json")
    |> response.set_body(json.to_string(result))
    |> response.map(bytes_builder.from_string)
    |> response.map(mist.Bytes)
}

fn send(resp: Response(body), value: String) -> Response(ResponseData) {
    resp 
    |> response.prepend_header("Powered-By", "Gleam")
    |> response.prepend_header("Content-Type", "text/plain")
    |> response.set_body(value)
    |> response.map(bytes_builder.from_string)
    |> response.map(mist.Bytes)
}
