
# List all recipes
default:
    just --choose

# Start the server, build drafts too
serve:
    hugo server --buildDrafts

# Deploy the blog to Git
deploy:
    git add -A
    git commit -m "$(gum input)"
    git push
