# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Client-side search
pin "fuse.js", to: "https://cdn.jsdelivr.net/npm/fuse.js@7.0.0/dist/fuse.mjs"
pin "lz-string", to: "https://esm.sh/lz-string@1.5.0"
