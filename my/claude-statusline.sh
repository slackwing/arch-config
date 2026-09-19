#!/bin/sh
# Claude Code status line: model · effort · est. $ (+ 5h/7d limits when
# the API reports them). Wired from ~/.claude/settings.json "statusLine"
# (not in this repo — see README.md), so every claude, including the
# numpad pads (--settings only overrides keys it names), inherits it.
# Claude Code pipes a JSON blob on stdin; docs: code.claude.com/docs/en/statusline
input=$(cat)
eval "$(printf '%s' "$input" | jq -r '
  @sh "model=\(.model.display_name // .model.id // "?")",
  @sh "effort=\(.effort.level // "")",
  @sh "think=\(.thinking.enabled // false)",
  @sh "cost=\(.cost.total_cost_usd // 0)",
  @sh "five=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "week=\(.rate_limits.seven_day.used_percentage // "")"
')"

sep=' \033[2m·\033[0m '
out="\033[1m${model}\033[0m"
[ -n "$effort" ] && out="${out}${sep}\033[36m${effort}\033[0m"
[ "$think" = true ] && out="${out}\033[2m+think\033[0m"
out="${out}${sep}\033[33m$(printf '$%.2f' "$cost")\033[0m"
lim=""
[ -n "$five" ] && lim="5h $(printf '%.0f' "$five")%"
[ -n "$week" ] && lim="${lim:+$lim }7d $(printf '%.0f' "$week")%"
[ -n "$lim" ] && out="${out}${sep}\033[2m${lim}\033[0m"
printf '%b' "$out"
