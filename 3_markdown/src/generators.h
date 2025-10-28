#ifndef GENERATORS_H
#define GENERATORS_H

#include "types.h"

// HTML generation functions
char* generate_html_from_ast(ASTNode* node);
char* generate_paragraph_html(ASTNode* node);
char* generate_escaped_html(const char* str);

// JSON generation functions
char* generate_ast_json(ASTNode* node);

#endif // GENERATORS_H
