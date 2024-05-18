%{
#include <stdio.h>

#include "y.tab.h"
#include "token.h"

int yywrap() {
  return 1;
}

%}

%%

"*" return MUL;
"/" return DIV;
"+" return ADD;
"-" return SUB;
"(" return L_BK;
")" return R_BK;

" " {}
"\t" {}

[1-9]+[0-9]* {
  yylval = atoi(yytext);
  return LITERAL_INT;
}

[\n] return CR;

. /* do nothing */

%%
