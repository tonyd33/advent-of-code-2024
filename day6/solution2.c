#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
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
  flat[i++] = '\0';
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
  return grid->flat[coord->y * grid->x_len + coord->x];
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

  if (oob(&new_pos, grid)) return true;

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

  int x = 0, y = 0, i = 0;
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

Array* make_grids(Grid* orig) {
  Array* grids = init_array();
  int flat_size = orig->x_len * orig->y_len;
  Grid* grid;
  Coord coord;
  char chr;

  for (int y = 0; y < orig->y_len; y++) {
    for (int x = 0; x < orig->x_len; x++) {
      coord = (Coord){x, y};
      chr = access_grid(&coord, orig);
      if (!(chr == '#' ||
           chr == '^' ||
           chr == 'v' ||
           chr == '>' ||
           chr == '<')) {
        grid = malloc(sizeof(Grid));
        grid->x_len = orig->x_len;
        grid->y_len = orig->y_len;
        grid->flat = malloc(sizeof(char) * flat_size);
        strncpy(grid->flat, orig->flat, flat_size);
        set_grid(&coord, '#', grid);
        push_array(grids, grid);
      }
    }
  }

  return grids;
}

bool is_guard_in_path(Array* path, Guard* guard) {
  Guard* curr_guard;
  for (int i = 0; i < path->len; i++) {
    curr_guard = (Guard*)(path->items[i]);
    if (curr_guard->coord.x == guard->coord.x &&
        curr_guard->coord.y == guard->coord.y &&
        curr_guard->ori == guard->ori) {
      printf("found at %d\n", i);
      return true;
    }
  }
  return false;
}

// returns true upon cycle detection. false otherwise
bool simulate_safe(Grid* grid) {
  Array* path = init_array();
  Guard orig_guard = {{0, 0}, '?'};
  if (!find_guard(grid, &orig_guard)) {
    fprintf(stderr, "[FATAL]: Could not find guard\n");
    exit(1);
  }

  Guard* guard_copy;
  bool cyclic = false;
  do {
    guard_copy = malloc(sizeof(Guard));
    *guard_copy = orig_guard;
    cyclic = is_guard_in_path(path, guard_copy);

    push_array(path, guard_copy);
  } while (!update_state(grid, &orig_guard) && !cyclic);

  for (int i = 0; i < path->len; i++) {
    free(path->items[i]);
  }
  free_array(path);

  return cyclic;
}

void free_grid(Grid* grid) {
  free(grid->flat);
  grid->flat = NULL;
  grid->x_len = 0;
  grid->y_len = 0;
}

int main(int argc, char** argv) {
  int opt;

  char* file = "./input0";
  bool verbose = false;
  while ((opt = getopt(argc, argv, "vi:")) != -1) {
    switch (opt) {
      case 'i':
        file = optarg;
        break;
      case 'v':
        verbose = true;
        break;
      case '?':
        fprintf(stderr, "Bad opt -%c\n", optopt);
        exit(1);
    }
  }

  printf("Reading %s\n", file);
  FILE* fp = fopen(file, "r");
  if (fp == NULL) {
    fprintf(stderr, "Unable to open input");
  }

  int file_len = fsize(fp);
  // a bit overallocated because we're skipping newlines
  char flat[file_len];
  flat[file_len - 1] = '\0';

  Grid grid = {0, 0, flat};
  load_file(fp, grid.flat, &grid.x_len, &grid.y_len);
  print_grid(&grid);

  Array* grids = make_grids(&grid);

  int num_cyclic = 0;

  for (int i = 0; i < grids->len; i++) {
    if (simulate_safe(grids->items[i])) num_cyclic++;
    if (verbose)
      printf("%d/%zu %.2f%%\n", i + 1, grids->len, ((float)i/grids->len) * 100);
  }
  // ok i have no idea why but the answer for the real input is 1 higher than
  // it should be. i've spent enough time on this problem. goodbye.
  printf("num_cyclic %d\n", num_cyclic);

  for (int i = 0; i < grids->len; i++) {
    free_grid(grids->items[i]);
    free(grids->items[i]);
  }

  free_array(grids);
  fclose(fp);
}
