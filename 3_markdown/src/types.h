#ifndef TYPES_H
#define TYPES_H

#include <stddef.h>

// Node types enum
typedef enum {
  NODE_DOCUMENT,
  NODE_HEADER,
  NODE_PARAGRAPH,
  NODE_CODE_BLOCK,
  NODE_LIST,
  NODE_LIST_ITEMS,
  NODE_LIST_ITEM,
  NODE_TEXT,
  NODE_LINK,
  NODE_IMAGE,
  NODE_LINE_BREAK,
  NODE_INLINE_CODE,
  NODE_HREF
} NodeType;

// Convert NodeType enum to string
const char* node_type_to_string(NodeType type);

// AST Node structure
typedef struct ASTNode {
  NodeType type;
  char* content;
  int level;
  struct ASTNode** children;
  int child_count;
} ASTNode;

// String builder for dynamic string construction
typedef struct StringBuilder {
  char* str;
  size_t length;
  size_t capacity;
} StringBuilder;

#endif // TYPES_H
