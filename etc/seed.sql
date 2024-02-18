DO $$
BEGIN
	INSERT INTO contas (limite, saldo)
	VALUES
		(800 * 100, 0),
		(1000 * 100, 0),
		(5000 * 100, 0),
		(10000 * 100, 0),
		(100000 * 100, 0);
END;
$$;