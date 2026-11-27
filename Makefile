GNO ?= gno

.PHONY: fmt lint test

fmt:
	$(GNO) fmt ./gno.land/...

lint:
	$(GNO) lint ./gno.land/p/faddat/burrow ./gno.land/r/faddat/burrow

test:
	$(GNO) test ./gno.land/p/faddat/burrow ./gno.land/r/faddat/burrow
