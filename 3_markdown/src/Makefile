build:
	yacc --debug -dv ./lexer.y
	lex ./tokenizer.l
	gcc ./y.tab.c ./lex.yy.c

build-wasm:
	yacc -dv ./lexer.y
	lex ./tokenizer.l
	emcc ./y.tab.c ./lex.yy.c -s EXIT_RUNTIME

