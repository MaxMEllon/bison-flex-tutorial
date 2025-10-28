#ifndef AST_H
#define AST_H

#include "types.h"

// AST Node operations
ASTNode* create_node(NodeType type, char* content, int level);
void add_child(ASTNode* parent, ASTNode* child);

// String builder operations
StringBuilder* sb_create();
void sb_append(StringBuilder* sb, const char* str);
void sb_append_char(StringBuilder* sb, char c);
void sb_append_format(StringBuilder* sb, const char* format, ...);
char* sb_to_string(StringBuilder* sb);
void sb_free(StringBuilder* sb);

#endif // AST_H
