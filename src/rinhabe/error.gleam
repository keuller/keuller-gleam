
pub type HttpError {
    BadRequest
    UnprocessableEntity
}

pub type AppError {
    Encoder
    Decoder
    NotFound
    Validation
    SaldoNaoAtualizado
    SaldoInsuficiente
    FalhaOperacao
}
