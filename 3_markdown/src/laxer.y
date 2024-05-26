%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yydebug = 1;
extern int yylex();
extern void yyerror(char * str);

%}

%union {
  char* str;
}

%token CR

%token L_SB R_SB
%token L_PT R_PT

%token STRING

%token EOT

%type <str> STRING

%%

Document
    :
    | Blocks
    | EOT
    ;

Blocks
    : Block
    | Blocks Block
    | EOT
    ;

Block
    : Paragrah
    ;

Paragrah
    : URL
    | String
    ;

URL
    : L_SB STRING R_SB L_PT STRING R_PT
    {
      printf("<a href='%s'>%s</a>", $2, $5);
    }
    ;

String
    : CR { printf("\n"); }
    | STRING CR { printf("%s\n", $1); }
    ;

%%

void yyerror(char * str) {
  printf("cause error: %s\n", str);
}

int main(int argc, char * argv[]) {
  extern int yyparse(void);
  extern FILE *yyin;
  yyin = argc < 2 ? stdin : fopen(argv[1], "r");

  do {
    if (yyparse()) {
      exit(1);
    }
  } while(!feof(yyin));

  return 0;
}
