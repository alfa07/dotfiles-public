# config.nu
#
# Installed by:
# version = "0.106.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

# def start-ssh-agent [] {
#     ssh-agent -s 
#     | lines 
#     | parse "{key}={value}; export {_}" 
#     | reduce -f {} {|it, acc| $acc | insert $it.key $it.value } 
#     | load-env
# 
#     ssh-add ~/.ssh/id_ed25519
# 
# }

def --env start-ssh-agent [] {
    let agent_output = (ssh-agent -s | lines | first 2 | str join "\n")
    
    let ssh_auth_sock = ($agent_output | parse -r 'SSH_AUTH_SOCK=([^;]+)' | get capture0.0)
    let ssh_agent_pid = ($agent_output | parse -r 'SSH_AGENT_PID=(\d+)' | get capture0.0)
    
    $env.SSH_AUTH_SOCK = $ssh_auth_sock
    $env.SSH_AGENT_PID = $ssh_agent_pid
    
    ssh-add ~/.ssh/id_ed25519
}

alias k = kubectl
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' # optional

source ~/.config/nu-atuin/init.nu

let fish_completer = {|spans|
    fish --command $"complete '--do-complete=($spans | str replace --all "'" "\\'" | str join ' ')'"
    | from tsv --flexible --noheaders --no-infer
    | rename value description
    | update value {|row|
      let value = $row.value
      let need_quote = ['\' ',' '[' ']' '(' ')' ' ' '\t' "'" '"' "`"] | any {$in in $value}
      if ($need_quote and ($value | path exists)) {
        let expanded_path = if ($value starts-with ~) {$value | path expand --no-symlink} else {$value}
        $'"($expanded_path | str replace --all "\"" "\\\"")"'
      } else {$value}
    }
}

let carapace_completer = {|spans: list<string>|
    carapace $spans.0 nushell ...$spans
    | from json
    | if ($in | default [] | where value =~ '^-.*ERR$' | is-empty) { $in } else { null }
}

# This completer will use carapace by default
let external_completer = {|spans|
    let expanded_alias = scope aliases
    | where name == $spans.0
    | get -o 0.expansion

    let spans = if $expanded_alias != null {
        $spans
        | skip 1
        | prepend ($expanded_alias | split row ' ' | take 1)
    } else {
        $spans
    }

    match $spans.0 {
        # carapace completions are incorrect for nu
        nu => $fish_completer
        # fish completes commits and branch names in a nicer way
        git => $fish_completer
        # carapace doesn't have completions for asdf
        asdf => $fish_completer
        _ => $carapace_completer
    } | do $in $spans
}

$env.config.completions = {
  external: {
      enable: true
      completer: $external_completer
  }
}

$env.EDITOR = 'nvim'
$env.config.edit_mode = 'vi'
$env.config.cursor_shape = {
  vi_insert: line  # I-beam cursor for vi insert mode
  vi_normal: block  # Block cursor for vi normal mode
  emacs: line       # Line cursor for emacs mode
}
$env.config.color_config = {
        # Solarized Light colors
        separator: "#586e75"
        leading_trailing_space_bg: { attr: "n" }
        header: { fg: "#859900" attr: "b" }
        empty: "#268bd2"
        bool: "#268bd2"
        int: "#d33682"
        duration: "#d33682"
        filesize: "#d33682"
        date: "#b58900"
        range: "#b58900"
        float: "#d33682"
        string: "#2aa198"
        nothing: "#93a1a1"
        binary: "#cb4b16"
        cell_path: "#2aa198"
        row_index: { fg: "#859900" attr: "b" }
        record: "#2aa198"
        list: "#2aa198"
        block: "#268bd2"
        hints: "#586e75"
        search_result: { bg: "#b58900" fg: "#fdf6e3" }
        shape_and: { fg: "#d33682" attr: "b" }
        shape_binary: { fg: "#d33682" attr: "b" }
        shape_block: { fg: "#268bd2" attr: "b" }
        shape_bool: "#2aa198"
        shape_closure: { fg: "#859900" attr: "b" }
        shape_custom: "#859900"
        shape_datetime: { fg: "#2aa198" attr: "b" }
        shape_directory: "#2aa198"
        shape_external: "#2aa198"
        shape_externalarg: { fg: "#859900" attr: "b" }
        shape_external_resolved: { fg: "#2aa198" attr: "b" }
        shape_filepath: "#2aa198"
        shape_flag: { fg: "#268bd2" attr: "b" }
        shape_float: { fg: "#d33682" attr: "b" }
        shape_garbage: { fg: "#fdf6e3" bg: "#dc322f" attr: "b" }
        shape_globpattern: { fg: "#2aa198" attr: "b" }
        shape_int: { fg: "#d33682" attr: "b" }
        shape_internalcall: { fg: "#2aa198" attr: "b" }
        shape_keyword: { fg: "#d33682" attr: "b" }
        shape_list: { fg: "#2aa198" attr: "b" }
        shape_literal: "#268bd2"
        shape_match_pattern: "#859900"
        shape_matching_brackets: { attr: "u" }
        shape_nothing: "#2aa198"
        shape_operator: "#b58900"
        shape_or: { fg: "#d33682" attr: "b" }
        shape_pipe: { fg: "#d33682" attr: "b" }
        shape_range: { fg: "#b58900" attr: "b" }
        shape_record: { fg: "#2aa198" attr: "b" }
        shape_redirection: { fg: "#d33682" attr: "b" }
        shape_signature: { fg: "#859900" attr: "b" }
        shape_string: "#859900"
        shape_string_interpolation: { fg: "#2aa198" attr: "b" }
        shape_table: { fg: "#268bd2" attr: "b" }
        shape_variable: "#d33682"
        shape_vardecl: "#d33682"
    }
