import gleam/result
import gleam/dynamic
import gleam/json.{object}
import gleam/pgo.{Returned}
import rinhabe/error.{type AppError, SaldoInsuficiente}
import rinhabe/database.{type DB}

pub type Conta {
  Conta(id: Int, limite: Int, saldo: Int)
}

pub fn new(limite: Int, saldo: Int) -> Conta {
  Conta(0, limite, saldo)
}

pub fn get_conta(db: DB, id: Int) -> Result(Conta, AppError) {
    let query = "SELECT id, limite, saldo FROM contas WHERE id = $1"

    use res <- result.try(
        pgo.execute(query, db, [pgo.int(id)], conta_row_decoder())
        |> result.map_error(fn(_) { error.NotFound })
    )
    
    case res {
        Returned(c, [row]) if c > 0 -> Ok(row)
        Returned(_, _) -> Error(error.NotFound)
    }
}

pub fn valida_saldo(conta: Conta, valor: Int) -> Result(Conta, AppError) {
    let saldo_limite = conta.limite * -1
    let saldo_futuro = conta.saldo - valor
    case saldo_futuro {
        saldo_futuro if saldo_futuro >= saldo_limite -> Ok(conta)
        _ -> Error(SaldoInsuficiente)
    }
}

fn conta_row_decoder() -> dynamic.Decoder(Conta) {
  dynamic.decode3(
    Conta,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, dynamic.int),
    dynamic.element(2, dynamic.int)
  )
}

pub fn to_json(conta: Conta) -> json.Json {
  object([
    #("limite", json.int(conta.limite)),
    #("saldo", json.int(conta.saldo)),
  ])
}
