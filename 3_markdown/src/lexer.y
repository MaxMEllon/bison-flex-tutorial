%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "types.h"
#include "ast.h"
#include "generators.h"

# ifdef __EMSCRIPTEN__
# include <emscripten.h>
# else
# define EMSCRIPTEN_KEEPALIVE
# endif


int yydebug = 0;
int output_ast = 0;
struct ASTNode* document_root = NULL;
extern int yylex();
extern void yyerror(char * str);

// Flex buffer management functions
typedef struct yy_buffer_state *YY_BUFFER_STATE;
extern YY_BUFFER_STATE yy_scan_string(const char* str);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);

%}

%union {
  char* str;
  int level;
  struct ASTNode* node;
}

%token CR
%token HEAD
%token LIST_ITEM
%token L_SB R_SB
%token L_PT R_PT
%token EXCLAM
%token BACKTICK
%token CODE_BLOCK
%token STRING
%token EOT

%type <str> STRING HeaderText CodeContent
%type <level> HeaderLevel LIST_ITEM
%type <node> Document Blocks Block Header Paragraph InlineElements InlineElement URL Image InlineCode String CodeBlock List ListItems ListItem LinkInlineElements LinkInlineElement

%%

Document
    : {
        $$ = create_node(NODE_DOCUMENT, NULL, 0);
        document_root = $$;
    }
    | Blocks {
        $$ = $1;
        document_root = $$;
    }
    | EOT {
        $$ = create_node(NODE_DOCUMENT, NULL, 0);
        document_root = $$;
    }
    ;

Blocks
    : Block {
        if ($1 == NULL) {
            $$ = create_node(NODE_DOCUMENT, NULL, 0);  // Empty document if block is null
        } else {
            $$ = create_node(NODE_DOCUMENT, NULL, 0);
            add_child($$, $1);
        }
    }
    | Blocks Block {
        $$ = $1;
        if ($2 != NULL) {  // Only add non-null blocks
            add_child($$, $2);
        }
    }
    | EOT { $$ = create_node(NODE_DOCUMENT, NULL, 0); }
    ;

Block
    : Header { $$ = $1; }
    | Paragraph {
        if ($1 == NULL) {
            $$ = NULL;  // Skip empty paragraphs
        } else {
            $$ = $1;
        }
    }
    | CodeBlock { $$ = $1; }
    | List { $$ = $1; }
    ;

Header
    : HeaderLevel HeaderText
    {
      $$ = create_node(NODE_HEADER, $2, $1);
    }
    ;

HeaderText
    : STRING { $$ = $1; }
    ;

HeaderLevel
    : HEAD { $$ = 1; }
    | HeaderLevel HEAD { $$ = $1 + 1; }
    ;

Paragraph
    : InlineElements {
        if ($1 == NULL) {
            $$ = NULL;  // Empty paragraph
        } else {
            $$ = $1;
        }
    }
    ;

InlineElements
    : InlineElement {
        // Skip if it's just a line break
        if ($1->type == NODE_LINE_BREAK) {
            $$ = NULL;
        } else {
            $$ = create_node(NODE_PARAGRAPH, NULL, 0);
            add_child($$, $1);
        }
    }
    | InlineElements InlineElement {
        if ($1 == NULL) {
            // First element was a line break, treat this as the first real element
            if ($2->type == NODE_LINE_BREAK) {
                $$ = NULL;
            } else {
                $$ = create_node(NODE_PARAGRAPH, NULL, 0);
                add_child($$, $2);
            }
        } else {
            $$ = $1;
            add_child($$, $2);
        }
    }
    ;

InlineElement
    : Image { $$ = $1; }
    | URL { $$ = $1; }
    | InlineCode { $$ = $1; }
    | String { $$ = $1; }
    ;

URL
    : L_SB LinkInlineElements R_SB L_PT STRING R_PT
    {
      $$ = create_node(NODE_LINK, NULL, 0);
      // Add all link content children
      for (int i = 0; i < $2->child_count; i++) {
        add_child($$, $2->children[i]);
      }
      // Add href as last child
      ASTNode* href = create_node(NODE_HREF, $5, 0);
      add_child($$, href);
    }
    ;

LinkInlineElements
    : LinkInlineElement {
        $$ = create_node(NODE_PARAGRAPH, NULL, 0);
        add_child($$, $1);
    }
    | LinkInlineElements LinkInlineElement {
        $$ = $1;
        add_child($$, $2);
    }
    ;

LinkInlineElement
    : Image { $$ = $1; }
    | InlineCode { $$ = $1; }
    | String { $$ = $1; }
    ;

Image
    : EXCLAM L_SB STRING R_SB L_PT STRING R_PT
    {
      $$ = create_node(NODE_IMAGE, $3, 0);
      ASTNode* src = create_node(NODE_HREF, $6, 0);
      add_child($$, src);
    }
    ;

InlineCode
    : BACKTICK STRING BACKTICK
    {
      $$ = create_node(NODE_INLINE_CODE, $2, 0);
    }
    ;

String
    : STRING {
        $$ = create_node(NODE_TEXT, $1, 0);
    }
    | CR {
        $$ = create_node(NODE_LINE_BREAK, "\n", 0);
        // Don't output \n directly here, let paragraph handle it
    }
    ;

CodeBlock
    : CODE_BLOCK CodeContent CODE_BLOCK
    {
      $$ = create_node(NODE_CODE_BLOCK, $2, 0);
    }
    ;

CodeContent
    : STRING { $$ = $1; }
    | CodeContent STRING {
        char* combined = malloc(strlen($1) + strlen($2) + 1);
        strcpy(combined, $1);
        strcat(combined, $2);
        $$ = combined;
        free($1);
    }
    ;

List
    : ListItems {
        $$ = create_node(NODE_LIST, NULL, 0);
        for (int i = 0; i < $1->child_count; i++) {
            add_child($$, $1->children[i]);
        }
    }
    ;

ListItems
    : ListItem {
        $$ = create_node(NODE_LIST_ITEMS, NULL, 0);
        add_child($$, $1);
    }
    | ListItems ListItem {
        $$ = $1;
        add_child($$, $2);
    }
    ;

ListItem
    : LIST_ITEM STRING CR {
        $$ = create_node(NODE_LIST_ITEM, $2, $1);
    }
    | LIST_ITEM STRING {
        $$ = create_node(NODE_LIST_ITEM, $2, $1);
    }
    ;

%%

void yyerror(char * str) {
  printf("cause error: %s\n", str);
}

// Parse a markdown string and return the result as HTML
EMSCRIPTEN_KEEPALIVE
int parse_markdown(const char* input) {
  // Reset document root
  document_root = NULL;
  output_ast = 0;  // HTML mode

  // Use yy_scan_string to parse from a string instead of yyin
  YY_BUFFER_STATE buffer = yy_scan_string(input);

  // Parse the input
  int result = yyparse();

  // Output HTML from AST
  if (document_root) {
    printf("<article id=\"mr\">\n");
    char* html = generate_html_from_ast(document_root);
    printf("%s", html);
    free(html);
    printf("</article>\n");
  }

  // Clean up the buffer
  yy_delete_buffer(buffer);

  return result;
}

// Parse a markdown string and return the result as AST JSON
EMSCRIPTEN_KEEPALIVE
int parse_markdown_as_ast(const char* input) {
  // Reset document root
  document_root = NULL;
  output_ast = 1;  // AST mode

  // Use yy_scan_string to parse from a string instead of yyin
  YY_BUFFER_STATE buffer = yy_scan_string(input);

  // Parse the input
  int result = yyparse();

  // Output AST as JSON
  if (document_root) {
    char* json = generate_ast_json(document_root);
    printf("%s", json);
    free(json);
  }

  // Clean up the buffer
  yy_delete_buffer(buffer);

  return result;
}

int main(int argc, char * argv[]) {
  extern int yyparse(void);
  extern FILE *yyin;

  // Parse command line arguments to determine output mode
  // --ast flag: output AST JSON
  // no flags: output HTML
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--ast") == 0) {
      output_ast = 1;
    }
  }

  // Always use stdin for input
  yyin = stdin;

  // Parse the input
  if (yyparse()) {
    exit(1);
  }

  // Output results based on the --ast flag
  if (output_ast && document_root) {
    char* json = generate_ast_json(document_root);
    printf("%s", json);
    free(json);
  } else if (!output_ast && document_root) {
    // Output HTML from AST
    printf("<article id=\"mr\">\n");
    char* html = generate_html_from_ast(document_root);
    printf("%s", html);
    free(html);
    printf("</article>\n");
  }

  return 0;
}
