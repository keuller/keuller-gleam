import birl
import gleam/int
import gleam/result
import gleam/json.{object}
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import mist.{type Connection, type ResponseData}
import rinhabe/error
import rinhabe/server/web
import rinhabe/database
import rinhabe/domain/conta
import rinhabe/domain/transacao

// request body length is 1024 * 1024 * 10
const body_max_length = 10_485_760

type HandleFn = fn(Request(Connection)) -> Response(ResponseData)

fn parse_id(value: String) -> Int {
    int.parse(value) |> result.unwrap(0)
}

pub fn request_handler(db: database.DB) -> HandleFn {
    fn(req: Request(Connection)) -> Response(ResponseData) {
        let context = web.Context(db, req)
        
        case req.method, request.path_segments(req) {
            Get, [] -> web.default_response()
            Get, ["health"] -> web.health_check(context)
            Get, ["clientes", id, "extrato"] -> parse_id(id) |> obter_extrato(context)
            Post, ["clientes", id, "transacoes"] -> parse_id(id) |> criar_transacao(context)
            _, _ -> web.not_found(context, "")
        }
    }
}

fn criar_transacao(id: Int, ctx: web.Context) -> Response(ResponseData) {
    let assert Ok(req) = mist.read_body(ctx.req, body_max_length)

    case transacao.decode_transacao_request(req.body) {
        Error(_) -> web.unprocessable_entity("Solicitacao invalida")
        Ok(tx) -> {
            case transacao.nova_transacao(ctx.db, id, tx.valor, tx.tipo, tx.descricao) {
                Ok(c) -> conta.to_json(c) |> web.send_json()
                Error(err) -> case err {
                    error.NotFound -> web.not_found(ctx, "Conta nao encontrada")
                    error.FalhaOperacao -> web.bad_request()
                    error.SaldoInsuficiente -> web.unprocessable_entity("Saldo insuficiente")
                    _ -> web.internal_server_error()
                }
            }
        }
    }
}

fn obter_extrato(id: Int, ctx: web.Context) -> Response(ResponseData) {

    case transacao.obter_extrato(ctx.db, id) {
        Ok(lista) -> {
            let #(limite, total) = transacao.somar_valor(lista, 0, 0)
            object([
                #("saldo", object([
                    #("total", json.int(total)),
                    #("limite", json.int(limite)),
                    #("data_extrato", json.string(birl.to_iso8601(birl.now())))
                ])),
                #("transacoes", json.array(lista, transacao.to_json))
            ]) |> web.send_json()
        }
        Error(err) -> case err {
            error.NotFound -> web.not_found(ctx, "Conta nao encontrada")
            error.FalhaOperacao -> web.bad_request()
            _ -> web.internal_server_error()
        }
    }
}
