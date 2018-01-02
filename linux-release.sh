#!/bin/bash

installed="$(uname -r) $(uname -v | cut -d' ' -f5,6,7,8,9)"
html=$(curl -fsSL "https://www.kernel.org/" 2>/dev/null)
stable=$(grep -m1 -A2 "stable:" <<<"$html" | sed 's!td\|strong\|<\|>\|/\| !!g' | tr '\n' ' ')
mainline=$(grep -m1 -A2 "mainline:" <<<"$html" | sed 's!td\|strong\|<\|>\|/\| !!g' | tr '\n' ' ')
longterm=$(grep -m1 -A2 "longterm:" <<<"$html" | sed 's!td\|strong\|<\|>\|/\| !!g' | tr '\n' ' ')

echo -e "Installed: ${installed}\n\nLatest ${stable}\n\nLatest ${mainline}\n\nLatest ${longterm}"
