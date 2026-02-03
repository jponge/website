default:
    hugo server --buildDrafts --watch

create-post name:
    hugo new content content/posts/{{name}}/index.md

sync-theme:
    git submodule init
    git submodule update
