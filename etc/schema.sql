CREATE TABLE contas (
    id SERIAL,
    limite INTEGER NOT NULL,
    saldo INTEGER NOT NULL,
    CONSTRAINT pk_contas PRIMARY KEY (id)
);

CREATE TABLE transacoes (
    id SERIAL,
    conta_id INTEGER NOT NULL,
    valor INTEGER NOT NULL,
    operacao CHAR(1) NOT NULL,
    descricao VARCHAR(10) NOT NULL,
    registrado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_transacoes PRIMARY KEY (id)
);

CREATE OR REPLACE PROCEDURE criar_transacao(IN pconta int, IN pvalor int, IN ptipo TEXT, IN pdesc TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE contas SET saldo = saldo + pvalor WHERE id = pconta;
  INSERT INTO transacoes (conta_id, valor, operacao, descricao) VALUES (pconta, pvalor, ptipo, pdesc);
  COMMIT;
END;
$$