%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "y.tab.h"
#include "token.h"

int yywrap() {
  return 1;
}

/*
 * square brackets
 *    `[`
 *    `]`
 */

/*
 * parentheses
 *    `(`
 *    `)`
 */
%}

%%

"[" return L_SB;
"]" return R_SB;

"(" return L_PT;
")" return R_PT;

[\n] return CR;

[A-Za-z:/.\ ]+ {
  char* str;
  str = (char *) calloc(sizeof(char), strlen(yytext) + 1);
  strcpy(str, yytext);
  yylval.str = str;
  return STRING;
}

. /* do nothing */

%%
