# 1. Syncs the CONTENTS of ./noctalia into ~/.config/noctalia/
rsync -rtu ./noctalia/ ~/.config/noctalia/

# 2. Syncs the CONTENTS of ~/.config/noctalia into the current ./noctalia/ folder
rsync -rtu ~/.config/noctalia/ ./noctalia/
