This is a factual question about Claude Code setup — this is exactly what claude-code-guide is for.User wants to run multiple Claude Code agents at once using tmux (running several Claude Code sessions in parallel panes/windows, each possibly working on a different task or git worktree).

Please answer: what does the user need to set this up? Cover:
1. Prerequisites (tmux installed, Claude Code CLI installed/authenticated)
2. Basic tmux commands needed for this workflow (new session, splitting panes/windows, switching between them, detach/reattach)
3. How to actually run multiple Claude Code instances in parallel this way (e.g. one per pane/window, optionally using git worktrees per agent to avoid file conflicts)
4. Any relevant Claude Code features that help with parallel/multi-agent workflows (e.g. git worktree support, background tasks, --dangerously-skip-permissions considerations, etc.)
5. Any gotchas (shared file conflicts, context/cost considerations, permissions prompts blocking in background panes)

Keep the answer practical and concise, aimed at someone setting this up for the first time. Report back in under 350 words, organized so I can relay it directly to the user.