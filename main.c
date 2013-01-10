

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"


#ifndef INSTALL_DIR
#define INSTALL_DIR "."
#endif // INSTALL_DIR


int luaopen_buffer(lua_State *L);
int luaopen_hdf5(lua_State *L);
int luaopen_mpi(lua_State *L);
int luaopen_cow(lua_State *L);
int luaopen_Mara(lua_State *L);

int main(int argc, char **argv)
{
  int n;
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);
  luaL_requiref(L, "buffer", luaopen_buffer, 0); lua_pop(L, 1);
  luaL_requiref(L, "HDF5", luaopen_hdf5, 0); lua_pop(L, 1);
  luaL_requiref(L, "MPI", luaopen_mpi, 0); lua_pop(L, 1);
  luaL_requiref(L, "cow", luaopen_cow, 0); lua_pop(L, 1);
  luaL_requiref(L, "Mara", luaopen_Mara, 0); lua_pop(L, 1);


  // Create the global `arg` table
  // ---------------------------------------------------------------------------
  lua_newtable(L);
  for (n=0; n<argc; ++n) {
    lua_pushstring(L, argv[n]);
    lua_rawseti(L, -2, n);
  }
  lua_setglobal(L, "arg");


  // Set the Lua path
  // ---------------------------------------------------------------------------
  lua_getglobal(L, "package");
  lua_pushfstring(L, "%s/lua-glut/?.bundle", INSTALL_DIR);
  lua_setfield(L, -2, "cpath");
  lua_pop(L, 1);

  lua_getglobal(L, "package");
  lua_pushfstring(L,
  		  "%s/modules/?.lua;"
		  "%s/lua-hdf5/?.lua;"
		  "%s/lua-mpi/?.lua;"
		  "%s/lua-glut/?.lua;"
		  "%s/lua-buffer/?.lua;",
		  INSTALL_DIR,
		  INSTALL_DIR,
		  INSTALL_DIR,
		  INSTALL_DIR,
		  INSTALL_DIR);
  lua_setfield(L, -2, "path");
  lua_pop(L, 1);


  // Run the script
  // ---------------------------------------------------------------------------
  if (argc == 1) {
    printf("usage: main script.lua [arg1=val1 arg2=val2]\n");
  }
  else {
    char luacode[4096];
    snprintf(luacode, 4096, "\
    local f, err = loadfile('%s')\n					\
    if not f then\n							\
      print(err)\n							\
    else								\
      local success, msg = xpcall(f, debug.traceback)\n			\
      if not success then\n						\
         print(msg)\n							\
      end\n								\
    end\n", argv[1]);
    int err = luaL_dostring(L, luacode);
    if (err) {
      printf("%s\n", lua_tostring(L, -1));
    }
  }
  lua_close(L);
  return 0;
}
