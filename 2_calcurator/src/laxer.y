%{

#include <stdio.h>

extern int yylex();
extern void yyerror(char * str);

%}

%token CR

%token L_BK R_BK

%token ADD SUB
%token MUL DIV

%token LITERAL_INT

%token EOT

%left '+' '-'
%left '*' '/'

%%

input : line
      | input line
      ;

line :
     | line expr CR { printf(">> %d", $2); }
     | line EOT

expr : expr ADD expr { $$ = $1 + $3; }
     | expr SUB expr { $$ = $1 - $3; }
     | expr MUL expr { $$ = $1 * $3; }
     | expr DIV expr { $$ = $1 / $3; }
     | LITERAL_INT { $$ = $1; }
     | L_BK expr R_BK { $$ =  $2;  }
     ;
%%

void yyerror(char * str) {
  printf("cause error: %s\n", str);
}

void main() {
  yyparse();
}
