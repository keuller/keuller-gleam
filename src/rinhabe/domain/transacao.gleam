import gleam/int
import gleam/pgo
import gleam/json.{object}
import gleam/float
import gleam/result
import gleam/dynamic.{field, type DecodeErrors, type Dynamic}
import rinhabe/error.{type AppError}
import rinhabe/database.{type DB}
import rinhabe/domain/conta

type DatePart = #(Int, Int, Int)
type TimePart = #(Int, Int, Float)

pub type Transacao {
    Transacao(
        id: Int, 
        conta_id: Int, 
        valor: Int, 
        operacao: String, 
        descricao: String, 
        registrado_em: String
    )
}


pub type TransacaoRequest {
    TransacaoRequest(valor: Int, tipo: String, descricao: String)
}

pub type Extrato {
    Extrato(valor: Int, limite: Int, tipo: String, descricao: String, registrado: String)
}

pub fn decode_transacao_request(value: BitArray) -> Result(TransacaoRequest, AppError) {
    let transacao_decoder = dynamic.decode3(
        TransacaoRequest,
        field("valor", of: dynamic.int),
        field("tipo", of: dynamic.string),
        field("descricao", of: dynamic.string),
    )

    json.decode_bits(value, using: transacao_decoder)
        |> result.map_error(fn(_) { error.Decoder })
}

pub fn nova_transacao(db: DB, conta_id: Int, valor: Int, tipo: String, desc: String) -> Result(conta.Conta, AppError) {
    let transacao = Transacao(0, conta_id, valor, tipo, desc, "")

    case conta.get_conta(db, conta_id) {
        Ok(c) if tipo == "c" -> credito(c, db, transacao)
        Ok(c) if tipo == "d" -> debito(c, db, transacao)
        Ok(_) -> Error(error.FalhaOperacao)
        Error(err) -> Error(err)
    }
}

fn credito(c: conta.Conta, db: DB, tx: Transacao) -> Result(conta.Conta, AppError) {
    let saldo_futuro = c.saldo + int.absolute_value(tx.valor) // calcula o saldo futuro
    let stmt = "CALL criar_transacao($1, $2, $3, $4)"
    let params = [pgo.int(c.id), pgo.int(tx.valor), pgo.text(tx.operacao), pgo.text(tx.descricao)]

    pgo.execute(stmt, db, params, dynamic.dynamic)
        |> result.map(fn(_) { conta.Conta(..c, saldo: saldo_futuro) })
        |> result.map_error(fn(_) { error.FalhaOperacao })
}

fn debito(c: conta.Conta, db: DB, tx: Transacao) -> Result(conta.Conta, AppError) {
    let tx_value = int.absolute_value(tx.valor) * -1 // forces negative value
    let saldo_futuro = c.saldo + tx_value // calcula o saldo futuro
    let valid_operacao = { c.limite * -1 } <= saldo_futuro

    let stmt = "CALL criar_transacao($1, $2, $3, $4)"
    let params = [pgo.int(c.id), pgo.int(tx_value), pgo.text(tx.operacao), pgo.text(tx.descricao)]

    case valid_operacao {
        True -> pgo.execute(stmt, db, params, dynamic.dynamic)
                |> result.map(fn(_) { conta.Conta(..c, saldo: saldo_futuro) })
                |> result.map_error(fn(_) { error.FalhaOperacao })
        False -> Error(error.SaldoInsuficiente)
    }
}

pub fn obter_extrato(db: DB, conta_id: Int) -> Result(List(Extrato), AppError) {
    let query = "
    SELECT t.valor, c.limite, t.operacao as tipo, t.descricao, t.registrado_em
    FROM contas c
    INNER JOIN transacoes t ON t.conta_id = c.id
    WHERE c.id = $1
    ORDER BY t.registrado_em DESC
    LIMIT 10
    "

    case pgo.execute(query, db, [pgo.int(conta_id)], extrato_decoder()) {
        Ok(returned) -> Ok(returned.rows)
        Error(_) -> Error(error.NotFound)
    }
}

fn extrato_decoder() -> dynamic.Decoder(Extrato) {
    dynamic.decode5(
        Extrato, 
        dynamic.element(0, dynamic.int), 
        dynamic.element(1, dynamic.int), 
        dynamic.element(2, dynamic.string), 
        dynamic.element(3, dynamic.string),
        dynamic.element(4, timestamp_decoder)
    )
}

fn timestamp_decoder(from data: Dynamic) -> Result(String, DecodeErrors) {
    let date_decoder = dynamic.tuple3(dynamic.int, dynamic.int, dynamic.int)
    let time_decoder = dynamic.tuple3(dynamic.int, dynamic.int, dynamic.float)
    let date_time_decoder = dynamic.tuple2(date_decoder, time_decoder)
    date_time_decoder(data) |> parse_timestamp()
}

fn parse_timestamp(res: Result(#(DatePart, TimePart), DecodeErrors)) -> Result(String, DecodeErrors) {
    let format = fn(v: Int) -> String { 
        case v {
            v if v < 10 -> "0" <> int.to_string(v)
            _ -> int.to_string(v)
        }
    }

    res |> result.map(fn(tp) {
        let date = tp.0
        let time = tp.1
        int.to_string(date.0) <> "-" <> format(date.1) <> "-" <> format(date.2) <> 
            "T" <> format(time.0) <> ":" <> format(time.1) <> ":" <> float.to_string(time.2) <> "Z"
    })
}

pub fn to_json(extrato: Extrato) -> json.Json {
  object([
    #("valor", json.int(extrato.valor)),
    #("tipo", json.string(extrato.tipo)),
    #("descricao", json.string(extrato.descricao)),
    #("realizada_em", json.string(extrato.registrado)),
  ])
}

pub fn somar_valor(lista: List(Extrato), limit: Int, value: Int) -> #(Int, Int) {
    case lista {
        [] -> #(limit, value)
        [item, ..rest] -> somar_valor(rest, item.limite, value + item.valor)
    }
}
