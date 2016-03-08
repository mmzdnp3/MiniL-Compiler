parser : lex.yy.c y.tab.c
	gcc -o parser y.tab.c lex.yy.c -lfl

lex.yy.c : mini_l.lex
	flex mini_l.lex

y.tab.c : mini_l.y
	bison -v -d --file-prefix=y mini_l.y

clean : 
	rm -f parser lex.yy.c y.output y.tab.h y.tab.c

test1 : FORCE parser
	cat samples/primes.min | ./parser

teste1 : FORCE parser
	cat samples/parser_error1.min | ./parser

teste2 : FORCE parser
	cat samples/parser_error2.min | ./parser

FORCE:
