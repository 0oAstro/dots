{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    neovim
    micro
    helix
  ];

  xdg.configFile = {
    "nvim/lua/generated-by-nix.lua" = let
      luaInterpreter = config.programs.neovim.package.lua;
    in {
      enable = true;
      text = ''
        local M = {}
        M.gcc_path = "${pkgs.gcc}/bin/gcc"
        M.lua_interpreter = "${luaInterpreter}"
        M.luarocks_executable = "${luaInterpreter.pkgs.luarocks_bootstrap}/bin/luarocks"
        return M
      '';
    };

    "nvim/luarocks-config-generated.lua" = let
      luaInterpreter = config.programs.neovim.package.lua;
      luarocksStore = luaInterpreter.pkgs.luarocks;
      luacurlPkg = luaInterpreter.pkgs.lua-curl;

      luarocksConfigAttr = lib.recursiveUpdate luarocksConfigAttr {
        rocks_trees = [
          {
            name = "rocks.nvim";
            root = "/home/teto/.local/share/nvim/rocks";
          }
          {
            name = "rocks-generated.nvim";
            root = "${luarocksStore}";
          }
          {
            name = "lua-curl";
            root = "${luacurlPkg}";
          }
          {
            name = "sqlite.lua";
            root = "${luaInterpreter.pkgs.sqlite}";
          }
        ];

        # to help some package need variables for lib-curl.lua to be installable
        variables = {
          # MYSQL_INCDIR = "${libmysqlclient.dev}/include/mysql";
          # MYSQL_LIBDIR = "${libmysqlclient}/lib/mysql";
        };
      };

      luarocksConfigStr = lib.generators.toLua {asBindings = false;} luarocksConfigAttr;
    in {
      enable = true;
      text = "return ${luarocksConfigStr}";
    };
  };
}
