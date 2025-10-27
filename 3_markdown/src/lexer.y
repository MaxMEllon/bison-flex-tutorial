%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yydebug = 0;
int output_ast = 0;
struct ASTNode* document_root = NULL;
extern int yylex();
extern void yyerror(char * str);

typedef struct ASTNode {
  char* type;
  char* content;
  int level;
  struct ASTNode** children;
  int child_count;
} ASTNode;

ASTNode* create_node(char* type, char* content, int level);
void add_child(ASTNode* parent, ASTNode* child);
void print_ast_json(ASTNode* node, int indent);
void print_paragraph_html(ASTNode* node);
void print_escaped_html(const char* str);

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
%token BACKTICK
%token CODE_BLOCK
%token STRING
%token EOT

%type <str> STRING HeaderText CodeContent
%type <level> HeaderLevel
%type <node> Document Blocks Block Header Paragraph InlineElements InlineElement URL InlineCode String CodeBlock List ListItems ListItem

%%

Document
    : {
        $$ = create_node("Document", NULL, 0);
        document_root = $$;
    }
    | Blocks {
        $$ = $1;
        document_root = $$;
    }
    | EOT {
        $$ = create_node("Document", NULL, 0);
        document_root = $$;
    }
    ;

Blocks
    : Block {
        if ($1 == NULL) {
            $$ = create_node("Document", NULL, 0);  // Empty document if block is null
        } else {
            $$ = create_node("Document", NULL, 0);
            add_child($$, $1);
        }
    }
    | Blocks Block {
        $$ = $1;
        if ($2 != NULL) {  // Only add non-null blocks
            add_child($$, $2);
        }
    }
    | EOT { $$ = create_node("Document", NULL, 0); }
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
      $$ = create_node("Header", $2, $1);
      if (!output_ast) {
        printf("<h%d>%s</h%d>\n", $1, $2, $1);
      }
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
            if (!output_ast) {
                print_paragraph_html($1);
            }
        }
    }
    ;

InlineElements
    : InlineElement {
        // Skip if it's just a line break
        if (strcmp($1->type, "LineBreak") == 0) {
            $$ = NULL;
        } else {
            $$ = create_node("Paragraph", NULL, 0);
            add_child($$, $1);
        }
    }
    | InlineElements InlineElement {
        if ($1 == NULL) {
            // First element was a line break, treat this as the first real element
            if (strcmp($2->type, "LineBreak") == 0) {
                $$ = NULL;
            } else {
                $$ = create_node("Paragraph", NULL, 0);
                add_child($$, $2);
            }
        } else {
            $$ = $1;
            add_child($$, $2);
        }
    }
    ;

InlineElement
    : URL { $$ = $1; }
    | InlineCode { $$ = $1; }
    | String { $$ = $1; }
    ;

URL
    : L_SB STRING R_SB L_PT STRING R_PT
    {
      $$ = create_node("Link", $2, 0);
      ASTNode* href = create_node("href", $5, 0);
      add_child($$, href);
    }
    ;

InlineCode
    : BACKTICK STRING BACKTICK
    {
      $$ = create_node("InlineCode", $2, 0);
    }
    ;

String
    : STRING {
        $$ = create_node("Text", $1, 0);
    }
    | CR {
        $$ = create_node("LineBreak", "\n", 0);
        // Don't output \n directly here, let paragraph handle it
    }
    ;

CodeBlock
    : CODE_BLOCK CodeContent CODE_BLOCK
    {
      $$ = create_node("CodeBlock", $2, 0);
      if (!output_ast) {
        printf("<pre><code>");
        print_escaped_html($2);
        printf("</code></pre>\n");
      }
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
        $$ = create_node("List", NULL, 0);
        for (int i = 0; i < $1->child_count; i++) {
            add_child($$, $1->children[i]);
        }
        if (!output_ast) {
            printf("<ul>\n");
            for (int i = 0; i < $1->child_count; i++) {
                printf("<li>%s</li>\n", $1->children[i]->content);
            }
            printf("</ul>\n");
        }
    }
    ;

ListItems
    : ListItem {
        $$ = create_node("ListItems", NULL, 0);
        add_child($$, $1);
    }
    | ListItems ListItem {
        $$ = $1;
        add_child($$, $2);
    }
    ;

ListItem
    : LIST_ITEM STRING CR {
        $$ = create_node("ListItem", $2, 0);
    }
    | LIST_ITEM STRING {
        $$ = create_node("ListItem", $2, 0);
    }
    ;

%%

void yyerror(char * str) {
  printf("cause error: %s\n", str);
}

ASTNode* create_node(char* type, char* content, int level) {
  ASTNode* node = malloc(sizeof(ASTNode));
  node->type = strdup(type);
  node->content = content ? strdup(content) : NULL;
  node->level = level;
  node->children = NULL;
  node->child_count = 0;
  return node;
}

void add_child(ASTNode* parent, ASTNode* child) {
  parent->children = realloc(parent->children, sizeof(ASTNode*) * (parent->child_count + 1));
  parent->children[parent->child_count] = child;
  parent->child_count++;
}

void print_ast_json(ASTNode* node, int indent) {
  if (!node) return;

  for (int i = 0; i < indent; i++) printf("  ");
  printf("{\n");

  for (int i = 0; i < indent + 1; i++) printf("  ");
  printf("\"type\": \"%s\"", node->type);

  if (node->content) {
    printf(",\n");
    for (int i = 0; i < indent + 1; i++) printf("  ");
    printf("\"content\": \"%s\"", node->content);
  }

  if (node->level > 0) {
    printf(",\n");
    for (int i = 0; i < indent + 1; i++) printf("  ");
    printf("\"level\": %d", node->level);
  }

  if (node->child_count > 0) {
    printf(",\n");
    for (int i = 0; i < indent + 1; i++) printf("  ");
    printf("\"children\": [\n");

    for (int i = 0; i < node->child_count; i++) {
      print_ast_json(node->children[i], indent + 2);
      if (i < node->child_count - 1) printf(",");
      printf("\n");
    }

    for (int i = 0; i < indent + 1; i++) printf("  ");
    printf("]");
  }

  printf("\n");
  for (int i = 0; i < indent; i++) printf("  ");
  printf("}");
}

void print_paragraph_html(ASTNode* node) {
  if (!node) return;

  printf("<p>");
  int has_trailing_space = 0;

  for (int i = 0; i < node->child_count; i++) {
    ASTNode* child = node->children[i];
    // Hash function for string switching
    unsigned int hash = 0;
    for (const char* s = child->type; *s; s++) {
      hash = hash * 31 + *s;
    }

    switch (hash) {
      // "Text"
      case 2603341:
        printf("%s", child->content);
        // Check if this text ends with space and is followed by LineBreak
        if (child->content && strlen(child->content) > 0) {
          char last_char = child->content[strlen(child->content) - 1];
          if (last_char == ' ' && i + 1 < node->child_count) {
            ASTNode* next = node->children[i + 1];
            if (strcmp(next->type, "LineBreak") == 0) {
              has_trailing_space = 1;
            }
          }
        }
        break;
      // "Link"
      case 2368538:
        {
          ASTNode* href = child->children[0]; // First child should be href
          printf("<a href='%s'>%s</a>", href->content, child->content);
        }
        break;
      // "LineBreak"
      case 181055819:
        if (has_trailing_space) {
          printf("</p>\n<p>");
          has_trailing_space = 0;  // Reset flag
        } else {
          printf("\n");
        }
        break;
      // "InlineCode"
      case 2771037254:
        printf("<code>");
        print_escaped_html(child->content);
        printf("</code>");
        break;
    }
  }
  printf("</p>\n");
}

void print_escaped_html(const char* str) {
  if (!str) return;

  for (int i = 0; str[i] != '\0'; i++) {
    switch (str[i]) {
      case '<':
        printf("&lt;");
        break;
      case '>':
        printf("&gt;");
        break;
      case '&':
        printf("&amp;");
        break;
      case '"':
        printf("&quot;");
        break;
      case '\'':
        printf("&#39;");
        break;
      default:
        printf("%c", str[i]);
        break;
    }
  }
}

int main(int argc, char * argv[]) {
  extern int yyparse(void);
  extern FILE *yyin;

  // Parse command line arguments
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--ast") == 0) {
      output_ast = 1;
    }
  }

  // Always use stdin for input
  yyin = stdin;

  // Output opening article tag for HTML mode
  if (!output_ast) {
    printf("<article id=\"mr\">\n");
  }

  if (yyparse()) {
    exit(1);
  }

  if (output_ast && document_root) {
    print_ast_json(document_root, 0);
    printf("\n");
  } else if (!output_ast) {
    // Output closing article tag for HTML mode
    printf("</article>\n");
  }

  return 0;
}
