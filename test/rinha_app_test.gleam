import gleeunit
import gleam/io
import gleeunit/should
import rinhabe/error
import rinhabe/domain/conta
import rinhabe/domain/transacao
import rinhabe/database

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn valida_saldo_test() {
  conta.new(1000, 0)
    |> conta.valida_saldo(500)
    |> should.be_ok()
}

pub fn valida_saldo_suficiente_limite_test() {
  conta.new(1000, 0)
    |> conta.valida_saldo(1000)
    |> should.be_ok()
}

pub fn valida_saldo_insuficiente_test() {
  conta.new(1000, 0)
    |> conta.valida_saldo(1001)
    |> should.be_error()
    |> should.equal(error.SaldoInsuficiente)
}

pub fn nova_transacao_credito() {
  let db = database.connect()
  transacao.nova_transacao(db, 1, 50, "c", "trasacaot3")
    |> should.be_ok()
    |> io.debug()
  database.disconnect(db)
}

pub fn nova_transacao_debito() {
  let db = database.connect()
  transacao.nova_transacao(db, 1, 10, "d", "trasacaot9")
    |> should.be_ok()
    |> io.debug()
  database.disconnect(db)
}