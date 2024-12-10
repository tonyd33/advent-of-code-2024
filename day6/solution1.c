#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <unistd.h>
#include "array.h"

#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

typedef struct Grid {
  int x_len;
  int y_len;
  char* flat;
} Grid;
typedef struct Coord { int x; int y; } Coord;
typedef Coord Vec2;
typedef struct Guard { Coord coord; char ori; } Guard;

void load_file(FILE* fp, char* flat, int* x_len, int* y_len) {
  char chr;
  int i = 0, row_len = 0, col_len = 0;
  while ((chr = fgetc(fp)) != EOF) {
    if (chr == '\n') {
      *x_len = MAX(*x_len, col_len);
      col_len = 0;
      row_len++;
    } else if (chr != '\n'){
      col_len++;
      flat[i++] = chr;
    }
  }
  *y_len = row_len;
  flat[i] = '\0';
}

int fsize(FILE* fp) {
  int len;
  int curr = ftell(fp);
  fseek(fp, 0, SEEK_END);
  len = ftell(fp);
  fseek(fp, curr, SEEK_SET);
  return len;
}

void flat_idx_to_coord(int flat_idx, Grid* grid, Coord* coord) {
  coord->x = flat_idx % grid->x_len;
  coord->y = flat_idx / grid->y_len;
}

void coord_to_flat_idx(Coord* coord, Grid* grid, int* flat_idx) {
  *flat_idx = coord->y * grid->x_len + coord->x;
}

char access_grid(Coord* coord, Grid* grid) {
  int flat_idx;
  coord_to_flat_idx(coord, grid, &flat_idx);
  return grid->flat[flat_idx];
}

void set_grid(Coord* coord, char chr, Grid* grid) {
  int flat_idx;
  coord_to_flat_idx(coord, grid, &flat_idx);
  grid->flat[flat_idx] = chr;
}

void ori_to_vec(char ori, Vec2* out) {
  switch (ori) {
    case '^':
      *out = (Vec2){0, -1};
      break;
    case 'v':
      *out = (Vec2){0, 1};
      break;
    case '<':
      *out = (Vec2){-1, 0};
      break;
    case '>':
      *out = (Vec2){1, 0};
      break;
  }
}

char vec_to_ori(Vec2* vec) {
  if (vec->y < 0) return '^';
  else if (vec->y > 0) return 'v';
  else if (vec->x < 0) return '<';
  else if (vec->x > 0) return '>';
  else return '?';
}

void rotate_vec_90_cw(Vec2* out) {
  *out = (Vec2){-out->y, out->x};
}

void get_move_vec(Grid* grid, Vec2* ori_vec, Coord* pos, Vec2* out) {
  Vec2 potential_vec = {ori_vec->x + pos->x, ori_vec->y + pos->y};
  out->x = ori_vec->x;
  out->y = ori_vec->y;

  if (access_grid(&potential_vec, grid) == '#') {
    rotate_vec_90_cw(out);
  }
}

bool oob(Coord* pos, Grid* grid) {
  return pos->x < 0 ||
         pos->y < 0 ||
         pos->x >= grid->x_len ||
         pos->y >= grid->y_len;
}

bool update_state(Grid* grid, Guard* guard) {
  Vec2 ori_vec;
  Vec2 move_vec;
  Coord new_pos;
  char ori;

  ori_to_vec(guard->ori, &ori_vec);
  get_move_vec(grid, &ori_vec, &guard->coord, &move_vec);
  ori = vec_to_ori(&move_vec);
  new_pos = (Coord){ move_vec.x + guard->coord.x, move_vec.y + guard->coord.y };

  if (oob(&new_pos, grid)) {
    return true;
  }

  set_grid(&guard->coord, '.', grid);
  guard->ori = ori;
  guard->coord = new_pos;
  set_grid(&guard->coord, ori, grid);
  return false;
}

void print_grid(Grid* grid) {
  // + 1 for extra new line
  int buf_len = (grid->x_len * grid->y_len) + grid->y_len + 2;
  char buf[buf_len];

  int x, y, i = 0;
  Coord coord;
  for (y = 0; y < grid->y_len; y++) {
    for (x = 0; x < grid->x_len; x++) {
      coord = (Coord){x, y};
      buf[i++] = access_grid(&coord, grid);
    }
    buf[i++] = '\n';
  }
  buf[i++] = '\n';
  buf[buf_len - 1] = '\0';
  printf("%s", buf);
}

bool find_guard(Grid* grid, Guard* out) {
  char chr;
  Coord coord;
  int x, y, x_len = grid->x_len, y_len = grid->y_len;
  for (y = 0; y < x_len; y++) {
    for (x = 0; x < y_len; x++) {
      coord = (Coord){x, y};
      chr = access_grid(&coord, grid);
      if (chr == '^' || chr == 'v' || chr == '>' || chr == '<') {
        out->coord.x = x;
        out->coord.y = y;
        out->ori = chr;
        return true;
      }
    }
  }
  return false;
}

int num_unique_pos(Array* positions) {
  Array* tmp_positions = init_array();
  int i, j;
  bool already_in;
  Coord* pos = NULL;
  Coord* tmp_pos = NULL;
  for (i = 0; i < positions->len; i++) {
    pos = (Coord*)(positions->items[i]);
    already_in = false;
    for (j = 0; j < tmp_positions->len; j++) {
      tmp_pos = (Coord*)(tmp_positions->items[j]);
      if (pos->x == tmp_pos->x && pos->y == tmp_pos->y) {
        already_in = true;
        break;
      }
    }

    if (!already_in) {
      push_array(tmp_positions, pos);
    }
  }

  int out = tmp_positions->len;

  free_array(tmp_positions);

  return out;
}

int main(int argc, char** argv) {
  int opt;

  char* file = "./input0";
  while ((opt = getopt(argc, argv, "i:")) != -1) {
    switch (opt) {
      case 'i':
        file = optarg;
        break;
      case '?':
        fprintf(stderr, "Bad opt -%c\n", optopt);
        exit(1);
    }
  }

  FILE* fp = fopen(file, "r");
  if (fp == NULL) {
    fprintf(stderr, "Unable to open input");
  }

  int file_len = fsize(fp);
  // a bit overallocated because we're skipping newlines
  char flat[file_len];

  Grid grid = {0, 0, flat};
  Guard guard = {{0, 0}, '?'};

  load_file(fp, grid.flat, &grid.x_len, &grid.y_len);
  if (!find_guard(&grid, &guard)) {
    fprintf(stderr, "Could not find guard\n");
    return 1;
  }

  Array* positions = init_array();
  Coord* temp_pos = NULL;
  do {
    temp_pos = malloc(sizeof(Coord));
    temp_pos->x = guard.coord.x;
    temp_pos->y = guard.coord.y;
    push_array(positions, temp_pos);
  } while (!update_state(&grid, &guard));

  int unique = num_unique_pos(positions);

  printf("%d\n", unique);

  for (int i = 0; i < positions->len; i++) {
    free(positions->items[i]);
  }
  free_array(positions);
}
