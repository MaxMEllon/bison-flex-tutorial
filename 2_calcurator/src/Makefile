build:
	yacc -dv ./laxer.y
	lex ./tokenizer.l
	gcc ./y.tab.c ./lex.yy.c
