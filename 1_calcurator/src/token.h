#ifndef __INC_GUARD_TOKEN_H__
#define __INC_GUARD_TOKEN_H__ 1

typedef enum {
  T_Int, 
} Type;

typedef struct Node {
  Type type;
  void * value;
} Int;

#endif
