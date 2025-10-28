#include "ast.h"
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>

// Convert NodeType enum to string
const char* node_type_to_string(NodeType type) {
  switch (type) {
    case NODE_DOCUMENT: return "Document";
    case NODE_HEADER: return "Header";
    case NODE_PARAGRAPH: return "Paragraph";
    case NODE_CODE_BLOCK: return "CodeBlock";
    case NODE_LIST: return "List";
    case NODE_LIST_ITEMS: return "ListItems";
    case NODE_LIST_ITEM: return "ListItem";
    case NODE_TEXT: return "Text";
    case NODE_LINK: return "Link";
    case NODE_IMAGE: return "Image";
    case NODE_LINE_BREAK: return "LineBreak";
    case NODE_INLINE_CODE: return "InlineCode";
    case NODE_HREF: return "href";
    default: return "Unknown";
  }
}

// StringBuilder implementation
StringBuilder* sb_create() {
  StringBuilder* sb = malloc(sizeof(StringBuilder));
  sb->capacity = 256;
  sb->length = 0;
  sb->str = malloc(sb->capacity);
  sb->str[0] = '\0';
  return sb;
}

static void sb_ensure_capacity(StringBuilder* sb, size_t additional) {
  size_t required = sb->length + additional + 1;
  if (required > sb->capacity) {
    while (sb->capacity < required) {
      sb->capacity *= 2;
    }
    sb->str = realloc(sb->str, sb->capacity);
  }
}

void sb_append(StringBuilder* sb, const char* str) {
  if (!str) return;
  size_t len = strlen(str);
  sb_ensure_capacity(sb, len);
  strcpy(sb->str + sb->length, str);
  sb->length += len;
}

void sb_append_char(StringBuilder* sb, char c) {
  sb_ensure_capacity(sb, 1);
  sb->str[sb->length++] = c;
  sb->str[sb->length] = '\0';
}

void sb_append_format(StringBuilder* sb, const char* format, ...) {
  va_list args;
  va_start(args, format);

  // Calculate required size
  va_list args_copy;
  va_copy(args_copy, args);
  int size = vsnprintf(NULL, 0, format, args_copy);
  va_end(args_copy);

  if (size < 0) {
    va_end(args);
    return;
  }

  sb_ensure_capacity(sb, size);
  vsnprintf(sb->str + sb->length, size + 1, format, args);
  sb->length += size;

  va_end(args);
}

char* sb_to_string(StringBuilder* sb) {
  char* result = strdup(sb->str);
  return result;
}

void sb_free(StringBuilder* sb) {
  if (sb) {
    free(sb->str);
    free(sb);
  }
}

// AST Node operations
ASTNode* create_node(NodeType type, char* content, int level) {
  ASTNode* node = malloc(sizeof(ASTNode));
  node->type = type;
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
