import { withHtmlLiveReload } from "./index.ts";

Bun.serve({
  fetch: withHtmlLiveReload(async () => {
    return new Response("<div>Init</div>", {
      headers: { "Content-Type": "text/html" },
    });
  }),
});
