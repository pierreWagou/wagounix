{ ... }: {

  programs.tmux = {
    enable = true;
    tmuxinator = {
      enable = true;
    };
    extraConfig = ''
      set -g default-terminal "tmux-256color"
      set -as terminal-features ',*:RGB'
      set -gq utf8-default on
      set -g prefix C-a
      set -sg escape-time 0
      set -g mouse on

      unbind C-b
      set -g prefix C-Space
      bind C-Space send-prefix

      set-option -g status-position bottom

      unbind r
      bind r source-file ~/.tmux.conf

      set -gq allow-passthrough on
      set -g visual-activity off

      # Window management
      set -g base-index 1
      set -g renumber-windows on
      set -g set-titles on
      setw -g automatic-rename on
      set -g automatic-rename-format "#{pane_current_path}"
      set -g set-titles-string "#S > #W"

      unbind n
      unbind p
      bind -r C-h previous-window
      bind -r C-l next-window

      # Pane management
      setw -g pane-base-index 1

      unbind %
      bind b split-window -h -c "#{pane_current_path}"
      unbind '"'
      bind v split-window -v -c "#{pane_current_path}"

      bind -r j resize-pane -D 5
      bind -r k resize-pane -U 5
      bind -r l resize-pane -R 5
      bind -r h resize-pane -L 6

      unbind -T root C-:
      bind -n C-z resize-pane -Z

      set-option -gw xterm-keys on

      unbind o
      bind -r ] copy-mode
      bind-key -T copy-mode-vi v send -X begin-selection
      bind-key -T copy-mode-vi C-v send -X rectangle-toggle
      bind-key -T copy-mode-vi y send -X copy-selection-and-cancel
      unbind -T copy-mode-vi MouseDragEnd1Pane # don't exit copy mode after dragging with mouse

      # Sesh config
      bind-key x kill-pane # skip "kill-pane 1? (y/n)" prompt
      set -g detach-on-destroy off  # don't exit from tmux when closing a session

      bind-key "f" display-popup -E -w 40% "sesh connect \"$(
        sesh list -i | gum filter --limit 1 --placeholder 'Pick a sesh' --prompt='⚡'
      )\""

      # Plugin management
      # tpm plugin manager
      set -g @plugin 'tmux-plugins/tpm'

      # list of tmux plugins
      set -g @plugin 'tmux-plugins/tmux-sensible'
      set -g @plugin 'christoomey/vim-tmux-navigator'
      set -g @plugin 'tmux-plugins/tmux-yank'
      set -g @plugin 'catppuccin/tmux'
      set -g @plugin 'b0o/tmux-autoreload'

      # plugins config
      set -g @resurrect-capture-pane-contents 'on' # allow tmux-ressurect to capture pane contents
      set -g @continuum-restore 'on' # enable tmux-continuum functionality

      # theme config
      set -g @catppuccin_flavor 'mocha'
      set -g @catppuccin_window_left_separator ""
      set -g @catppuccin_window_right_separator " "
      set -g @catppuccin_window_middle_separator " █"
      set -g @catppuccin_window_number_position "right"

      set -g @catppuccin_window_default_fill "number"
      set -g @catppuccin_window_default_text "#W"

      set -g @catppuccin_window_current_fill "number"
      set -g @catppuccin_window_current_text "#W"

      set -g @catppuccin_status_modules_right "session"
      set -g @catppuccin_status_left_separator  ""
      set -g @catppuccin_status_right_separator "█"
      set -g @catppuccin_status_fill "icon"
      set -g @catppuccin_status_connect_separator "yes"

      set -g @catppuccin_directory_text "#{pane_current_path}"

      # config for date_time module
      set -g @catppuccin_date_time_text "%d-%m-%Y %H:%M:%S"

      # Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
      run '~/.tmux/plugins/tpm/tpm'
    '';
  };  
}