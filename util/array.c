#include "array.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

Array* init_array() {
  Array* arr = malloc(sizeof(Array));
  arr->items = malloc(sizeof(void**));
  arr->_size = 1;
  arr->len = 0;
  return arr;
}

void push_array(Array* arr, void* item) {
  if (arr->len == arr->_size) {
    arr->_size *= 2;
    arr->items = realloc(arr->items, sizeof(void**) * arr->_size);
    if (arr->items == NULL) {
      fprintf(stderr, "[FATAL]: Failed to allocate array");
      exit(1);
    }
  }
  arr->items[arr->len++] = item;
}

void free_array(Array* arr) {
  free(arr->items);
  arr->items = NULL;
  arr->_size = 0;
  arr->len = 0;
  free(arr);
}

