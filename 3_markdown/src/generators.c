#include "generators.h"
#include "ast.h"
#include <stdlib.h>
#include <string.h>

// Internal function for JSON generation
static void generate_ast_json_internal(ASTNode* node, int indent, StringBuilder* sb) {
  if (!node) return;

  for (int i = 0; i < indent; i++) sb_append(sb, "  ");
  sb_append(sb, "{\n");

  for (int i = 0; i < indent + 1; i++) sb_append(sb, "  ");
  sb_append_format(sb, "\"type\": \"%s\"", node_type_to_string(node->type));

  if (node->content) {
    sb_append(sb, ",\n");
    for (int i = 0; i < indent + 1; i++) sb_append(sb, "  ");
    sb_append_format(sb, "\"content\": \"%s\"", node->content);
  }

  if (node->level > 0) {
    sb_append(sb, ",\n");
    for (int i = 0; i < indent + 1; i++) sb_append(sb, "  ");
    sb_append_format(sb, "\"level\": %d", node->level);
  }

  if (node->child_count > 0) {
    sb_append(sb, ",\n");
    for (int i = 0; i < indent + 1; i++) sb_append(sb, "  ");
    sb_append(sb, "\"children\": [\n");

    for (int i = 0; i < node->child_count; i++) {
      generate_ast_json_internal(node->children[i], indent + 2, sb);
      if (i < node->child_count - 1) sb_append(sb, ",");
      sb_append(sb, "\n");
    }

    for (int i = 0; i < indent + 1; i++) sb_append(sb, "  ");
    sb_append(sb, "]");
  }

  sb_append(sb, "\n");
  for (int i = 0; i < indent; i++) sb_append(sb, "  ");
  sb_append(sb, "}");
}

char* generate_ast_json(ASTNode* node) {
  if (!node) return strdup("");

  StringBuilder* sb = sb_create();
  generate_ast_json_internal(node, 0, sb);
  sb_append(sb, "\n");

  char* result = sb_to_string(sb);
  sb_free(sb);
  return result;
}

char* generate_paragraph_html(ASTNode* node) {
  if (!node) return strdup("");

  StringBuilder* sb = sb_create();
  sb_append(sb, "<p>");
  int has_trailing_space = 0;

  for (int i = 0; i < node->child_count; i++) {
    ASTNode* child = node->children[i];

    switch (child->type) {
      case NODE_TEXT:
        sb_append(sb, child->content);
        // Check if this text ends with space and is followed by LineBreak
        if (child->content && strlen(child->content) > 0) {
          char last_char = child->content[strlen(child->content) - 1];
          if (last_char == ' ' && i + 1 < node->child_count) {
            ASTNode* next = node->children[i + 1];
            if (next->type == NODE_LINE_BREAK) {
              has_trailing_space = 1;
            }
          }
        }
        break;
      case NODE_LINK:
        {
          if (child->child_count > 0) {
            // Last child is href, others are link content
            ASTNode* href = child->children[child->child_count - 1];
            sb_append_format(sb, "<a href='%s'>", href->content);

            // Render all children except the last one (href)
            for (int j = 0; j < child->child_count - 1; j++) {
              ASTNode* link_child = child->children[j];
              switch (link_child->type) {
                case NODE_TEXT:
                  sb_append(sb, link_child->content);
                  break;
                case NODE_IMAGE:
                  {
                    ASTNode* src = link_child->children[0];
                    sb_append_format(sb, "<img src='%s' alt='%s' />", src->content, link_child->content);
                  }
                  break;
                case NODE_INLINE_CODE:
                  {
                    sb_append(sb, "<code>");
                    char* escaped = generate_escaped_html(link_child->content);
                    sb_append(sb, escaped);
                    free(escaped);
                    sb_append(sb, "</code>");
                  }
                  break;
                default:
                  break;
              }
            }

            sb_append(sb, "</a>");
          }
        }
        break;
      case NODE_IMAGE:
        {
          ASTNode* src = child->children[0]; // First child should be src
          sb_append_format(sb, "<img src='%s' alt='%s' />", src->content, child->content);
        }
        break;
      case NODE_LINE_BREAK:
        if (has_trailing_space) {
          sb_append(sb, "</p>\n<p>");
          has_trailing_space = 0;  // Reset flag
        } else {
          // Check if next element is also a LINE_BREAK (empty line)
          if (i + 1 < node->child_count && node->children[i + 1]->type == NODE_LINE_BREAK) {
            sb_append(sb, "</p>\n<p>");
            i++;  // Skip the next LINE_BREAK
          } else {
            sb_append(sb, "\n");
          }
        }
        break;
      case NODE_INLINE_CODE:
        {
          sb_append(sb, "<code>");
          char* escaped = generate_escaped_html(child->content);
          sb_append(sb, escaped);
          free(escaped);
          sb_append(sb, "</code>");
        }
        break;
      default:
        break;
    }
  }
  sb_append(sb, "</p>\n");

  char* result = sb_to_string(sb);
  sb_free(sb);
  return result;
}

char* generate_escaped_html(const char* str) {
  if (!str) return strdup("");

  StringBuilder* sb = sb_create();

  for (int i = 0; str[i] != '\0'; i++) {
    switch (str[i]) {
      case '<':
        sb_append(sb, "&lt;");
        break;
      case '>':
        sb_append(sb, "&gt;");
        break;
      case '&':
        sb_append(sb, "&amp;");
        break;
      case '"':
        sb_append(sb, "&quot;");
        break;
      case '\'':
        sb_append(sb, "&#39;");
        break;
      default:
        sb_append_char(sb, str[i]);
        break;
    }
  }

  char* result = sb_to_string(sb);
  sb_free(sb);
  return result;
}

char* generate_html_from_ast(ASTNode* node) {
  if (!node) return strdup("");

  StringBuilder* sb = sb_create();

  switch (node->type) {
    case NODE_DOCUMENT:
      // Process all children
      for (int i = 0; i < node->child_count; i++) {
        char* child_html = generate_html_from_ast(node->children[i]);
        sb_append(sb, child_html);
        free(child_html);
      }
      break;

    case NODE_HEADER:
      sb_append_format(sb, "<h%d>%s</h%d>\n", node->level, node->content, node->level);
      break;

    case NODE_PARAGRAPH:
      {
        char* paragraph_html = generate_paragraph_html(node);
        sb_append(sb, paragraph_html);
        free(paragraph_html);
      }
      break;

    case NODE_CODE_BLOCK:
      {
        sb_append(sb, "<pre><code>");
        char* escaped = generate_escaped_html(node->content);
        sb_append(sb, escaped);
        free(escaped);
        sb_append(sb, "</code></pre>\n");
      }
      break;

    case NODE_LIST:
      {
        int current_level = -1;  // Start at -1 so first item opens <ul>
        for (int i = 0; i < node->child_count; i++) {
          ASTNode* item = node->children[i];
          if (item->type == NODE_LIST_ITEM) {
            int item_level = item->level;

            // Open nested lists if needed
            while (current_level < item_level) {
              sb_append(sb, "<ul>\n");
              current_level++;
            }

            // Close nested lists if needed
            while (current_level > item_level) {
              sb_append(sb, "</ul>\n");
              current_level--;
            }

            sb_append_format(sb, "<li>%s</li>\n", item->content);
          }
        }

        // Close all remaining open lists
        while (current_level >= 0) {
          sb_append(sb, "</ul>\n");
          current_level--;
        }
      }
      break;

    default:
      // For other node types, just process children if any
      for (int i = 0; i < node->child_count; i++) {
        char* child_html = generate_html_from_ast(node->children[i]);
        sb_append(sb, child_html);
        free(child_html);
      }
      break;
  }

  char* result = sb_to_string(sb);
  sb_free(sb);
  return result;
}
