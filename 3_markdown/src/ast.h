#ifndef __INC_GUARD_AST_H__
#define __INC_GUARD_AST_H__ 1

#include <stdlib.h>

typedef struct _AST {
  bool root;
  char * type;
  int attributeNum;
  char ** attribute;
  int childrenNum;
  struct _AST ** children;
} AST;

AST * createRoot(void);

#endif
