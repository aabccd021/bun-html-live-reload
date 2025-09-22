# bun-html-live-reload

HTML live reload for Bun.

## Getting Started

```sh
bun add -d bun-html-live-reload@github:aabccd021/bun-html-live-reload
```

```ts
import { withHtmlLiveReload, reload } from "bun-html-live-reload";

Bun.serve({
  fetch: withHtmlLiveReload(async (request) => {
    return new Response("<div>hello world</div>", {
      headers: { "Content-Type": "text/html" },
    });
  }),
});

// Refresh browser everytime the server is ready after hot reload
// You can call this function anywhere in your code to refresh browser
reload();
```

- Run the server with `bun --hot example.ts`, open browser, and try to edit the `hello world` part.
- The page should live reload as you edit!
- This plugin relies on response header to identify html response,
  so don't forget to add `"Content-Type": "text/html"` header to your `Response`.

## Options

You can specify URL paths used for server-sent events and live reloader script.

```ts
Bun.serve({
  fetch: withHtmlLiveReload(
    async (request) => {
      /* ... */
    },
    {
      // SSE Path
      // default: "/__dev__/reload"
      eventPath: "/__reload",

      // Live reload script path
      // default: "/__dev__/reload.js"
      scriptPath: "/__reload.js",
    },
  ),
});
```
