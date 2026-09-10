# VHS demo recording for whichllm
# Install: https://github.com/charmbracelet/vhs
# Run: cd assets && vhs demo.tape
# Output: demo.gif

Output demo.gif

Set FontSize 15
Set Width 1200
Set Height 1100
Set Theme "Catppuccin Mocha"
Set Padding 20
Set TypingSpeed 50ms

# Warm up cache invisibly
Hide
Type "uvx whichllm@latest --top 1 > /dev/null 2>&1"
Enter
Sleep 10s
Type "clear"
Enter
Sleep 500ms
Show

# Scene 1: Just run it
Type "uvx whichllm@latest"
Sleep 500ms
Enter
Sleep 6s
Sleep 2s

# Scene 2: What GPU do I need?
Type "uvx whichllm@latest plan 'qwen 72b'"
Sleep 500ms
Enter
Sleep 6s
Sleep 3s
