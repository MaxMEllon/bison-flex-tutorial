#include "ast.h"

AST * createRoot() {
  AST * ast = (AST*) malloc(sizeof(AST));
  ast->root = 1;
  ast->attributeNum = 0;
  ast->attribute = (char**) calloc(ast->attributeNum, sizeof(char*));
  ast->childrenNum = 0;
  ast->children = (AST**) calloc(ast->childrenNum, sizeof(AST*));
  return ast;
}

AST * createChild(AST * parent) {
  AST * ast = createRoot();
  ast->root = 0;
  parent->childrenNum += 1;
  parent->children = (AST**) realloc(ast->childrenNum, sizeof(AST*));
}