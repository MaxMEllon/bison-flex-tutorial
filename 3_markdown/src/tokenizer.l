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

%x CODEBLOCK

%%

"#"[ ]* return HEAD;

"[" return L_SB;
"]" return R_SB;

"(" return L_PT;
")" return R_PT;

"`" return BACKTICK;

"```" { BEGIN(CODEBLOCK); return CODE_BLOCK; }

<CODEBLOCK>"```" { BEGIN(INITIAL); return CODE_BLOCK; }
<CODEBLOCK>[^`\n]+ {
  char* str;
  str = (char *) calloc(sizeof(char), strlen(yytext) + 1);
  strcpy(str, yytext);
  yylval.str = str;
  return STRING;
}
<CODEBLOCK>\n {
  char* str;
  str = (char *) calloc(sizeof(char), 2);
  strcpy(str, "\n");
  yylval.str = str;
  return STRING;
}
<CODEBLOCK>"`" {
  char* str;
  str = (char *) calloc(sizeof(char), 2);
  strcpy(str, "`");
  yylval.str = str;
  return STRING;
}

\n return CR;

[A-Za-z0-9:/._ {};\-"',@=&?\x80-\xFF]+ {
  char* str;
  str = (char *) calloc(sizeof(char), strlen(yytext) + 1);
  strcpy(str, yytext);
  yylval.str = str;
  return STRING;
}

[ \t]+ /* ignore whitespace */

. /* ignore other characters */

%%
