# ttodo
A smol todo list TUI and CLI.

## Installing
- `sudo luarocks install ttodo` (requires `luarocks` and `lua`>=5.1)
- requires `tput` and `stty` in the PATH

## CLI Usage
### `$TODOFILE`
Sets the location of the todofile, defaults to `$HOME/.todofile`

### `ttodo show|list`
Displays the todo list with default format

### `ttodo edit|vi`
Opens the todo list in the default `$EDITOR` or `$VISUAL` (or `vi` if none is set)

### `ttodo cat`
Displays the content of the todofile

### `ttodo file`
Displays the path of the todofile

### `ttodo add <text>`
Adds a new item to the todo list

### `ttodo printf <fmt>`
Displays the todo list with the given format.  
`${field}` or `${field:minlen}` gets replaced by the given field (listed by `ttodo _fields`)  
`#{color}`, `#{r, g, b}` and `#{reset}` gets replaced by the corresponding ANSI escapes

### `ttodo count`
Returns the number of items in the todo list

### `ttodo _fields`
Lists the available fields for the `ttodo printf` command

### `ttodo _commands`
Lists the available subcommands

### `ttodo [tui]`
Opens the full terminal TUI

## TUI Usage
The up and down arrow keys move the cursor, which wraps around if top or bottom is reached.  
Blue pipes are visible at the top or bottom if the viewport is scrolled.  
All modifications are only done in memory until you explicitly save.  
Using shift with a command avoids the confirm prompt (for delete, save and quit).

## License
MIT
