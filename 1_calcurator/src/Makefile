build:
	yacc -dv ./src/laxer.y
	lex ./src/tokenizer.l
	gcc ./y.tab.c ./lex.yy.c
