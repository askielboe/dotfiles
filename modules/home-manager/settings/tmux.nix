{ ... }:

{
  programs.tmux = {
    enable = true;
    extraConfig = ''
      # Move current window up/down in window list with Ctrl+Option+hl
      bind-key -n C-M-h swap-window -t -1 \; select-window -t -1
      bind-key -n C-M-l swap-window -t +1 \; select-window -t +1

      # Switch between tmux windows with Ctrl+Option+jk (non-wrapping)
      bind-key -n C-M-j if-shell '[ "$(tmux display-message -p "#I")" -gt 1 ]' 'select-window -p'
      bind-key -n C-M-k if-shell '[ "$(tmux display-message -p "#I")" -lt "$(tmux list-windows | wc -l)" ]' 'select-window -n'

      # Switch to specific windows with Option+number
      bind-key -n M-1 select-window -t 1
      bind-key -n M-2 select-window -t 2
      bind-key -n M-3 select-window -t 3
      bind-key -n M-4 select-window -t 4
      bind-key -n M-5 select-window -t 5
      bind-key -n M-6 select-window -t 6
      bind-key -n M-7 select-window -t 7
      bind-key -n M-8 select-window -t 8
      bind-key -n M-9 select-window -t 9
      bind-key -n M-0 select-window -t 10

      # Basic tmux settings
      set -g default-terminal "screen-256color"
      set -g mouse on

      # Vi mode for copy mode (scrollback navigation)
      setw -g mode-keys vi

      # Vi-style copy mode bindings
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle

      # Start windows and panes at 1, not 0
      set -g base-index 1
      setw -g pane-base-index 1

      # Renumber windows when a window is closed
      set -g renumber-windows on

      # Shorten window names - show only directory name
      set -g automatic-rename on
      set -g automatic-rename-format '#{b:pane_current_path}'

      # Window status formatting with highlighting
      setw -g window-status-format ' #I:#W '
      setw -g window-status-current-format '#[bg=blue,fg=black,bold] #I:#W #[default]'
      setw -g window-status-separator ""

      # Status line configuration
      set -g status on
      set -g status-position top
      set -g status-interval 2

      # Status line content
      set -g status-left-length 30
      set -g status-right-length 120

      # Left side: session and window info
      set -g status-left "#[fg=green]#S #[fg=yellow]#I:#P "

      # Status right with system metrics
      set -g status-right " #[fg=cyan]\uf2db #(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | sed 's/ us,//') #[fg=magenta]\uf233 #(free | grep Mem | awk '{printf \"%.1f%%\", $3/$2 * 100.0}') #[fg=blue]\uf0a0 #(df -h / | awk 'NR==2{print $4}') "
    '';
  };
}

