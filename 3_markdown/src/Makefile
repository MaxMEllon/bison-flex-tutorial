build:
	yacc --debug -dv ./lexer.y
	lex ./tokenizer.l
	gcc ./y.tab.c ./lex.yy.c ./ast.c ./generators.c -o markdown

build-wasm:
	yacc -dv ./lexer.y
	lex ./tokenizer.l
	emcc ./y.tab.c ./lex.yy.c ./ast.c ./generators.c -s EXIT_RUNTIME

build-wasm-browser:
	yacc -dv ./lexer.y
	lex ./tokenizer.l
	emcc ./y.tab.c ./lex.yy.c ./ast.c ./generators.c -o markdown.html -sINVOKE_RUN=0 -sWASM=1 -sEXIT_RUNTIME -sEXPORTED_FUNCTIONS=_parse_markdown -sEXPORTED_RUNTIME_METHODS=ccall,cwrap
