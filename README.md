# bun-html-live-reload

HTML live reload for Bun

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

// Refresh browser when the server is ready after each hot reload
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

## LICENCE

```
Zero-Clause BSD
=============

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLEs
FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```
