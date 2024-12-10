#include <stdlib.h>
#include <stdio.h>
typedef struct Array { void** items; size_t len; size_t _size; } Array;

Array* init_array();
void push_array(Array* arr, void* item);
void free_array(Array* arr);
