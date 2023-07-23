local xdg_config_home = os.getenv('XDG_CONFIG_HOME') or os.getenv('HOME') .. '/.config'
local vimrc = xdg_config_home .. '/vim/vimrc'
-- local script_dir = vim.fn.expand('<script>:p:h')
vim.cmd('source ' .. vimrc)
