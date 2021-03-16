# VSCode configuration references

## Listing all available commands and default keybindings

- `workbench.action.openDefaultKeybindingsFile`
- The full list of commands (including ones provided by extensions) are
  commented out at the bottom of the file

## Debugging keybindings conditions

Update 2021-03-16: VSCode now supports has a
[Inspect Context Keys utility](https://code.visualstudio.com/api/references/when-clause-contexts#inspect-context-keys-utility)
which should is easier and less likely to break in future versions than the
steps below.

### Stored contexts

This directory contains files with the context variables for different contexts,
all collected from VSCode 1.49.1:

- [remote_python_file_context.txt](./remote_python_file_context.txt): remote SSH
  dev when the focus is on a Python file with code cells (using the `# %%`
  marker)
- [remote_python_interactive_context.txt](./remote_python_interactive_context.txt):
  remote SSH dev when the focus is on a Python interactive window
- [remote_terminal_context.txt](./remote_terminal_context.txt): remote SSH dev
  when the focus is on the terminal (connected to a remote shell)

### Legacy steps

As mentioned [in this issue](https://github.com/microsoft/vscode/issues/78782),
"when clauses" for keybindings are not fully documented. In order to get the
full context that can be used in when clauses, I did the following:

- `workbench.action.toggleKeybindingsLog`
- `workbench.action.toggleDevTools`
- Command palette -> "Developer: Toggle Keyboard Shortcuts Troubleshooting"
- Now the dev console should show logs on key presses. Click on the file name
  from the key press log.
- Add a breakpoint
- Go up the call stack to the function where the key press was logged
  ([`keybindingService.ts:252`](https://github.com/microsoft/vscode/blob/master/src/vs/workbench/services/keybinding/browser/keybindingService.ts#L252)
  as of writing this)
- Step into the code till you reach the line where the context is computed
  ([`abstractKeybindingService.ts:91`](https://github.com/microsoft/vscode/blob/master/src/vs/platform/keybinding/common/abstractKeybindingService.ts#L191)
  as of writing this)
- Add a breakpoint just after the context is computed
- Press a key in any context you're interested in
- Wait till the breakpoint is reached
- In the dev tools variable inspector, right click on `contextValue` and then
  select "Store as global variable"
- Print the context in the dev console. I used the following function:

  ```javascript
  printAndSaveContext = (ctx) => {
    values = {};
    while (ctx) {
      values = { ...values, ...ctx._value };
      ctx = ctx._parent;
    }
    console.log(
      Object.entries(values)
        .sort()
        .reduce((o, [k, v]) => ((o[k] = v), o), {})
    );
    copy(JSON.stringify(values));
  };
  printAndSaveContext(s);
  ```
