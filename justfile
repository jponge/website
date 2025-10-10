default:
    hugo server --buildDrafts

create-post name:
    hugo new content content/posts/{{name}}/index.md