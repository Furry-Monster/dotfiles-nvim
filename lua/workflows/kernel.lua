-- This policy applies equally to C++, Rust and mixed-language kernels.
-- Building stays in the editor; boot/testing/emulation/debugging stay in tmux.
return { external = { run = true, test = true, debug = true } }
