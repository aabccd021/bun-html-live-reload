import { withHtmlLiveReload } from "./index.js";

export default withHtmlLiveReload(
  {
    fetch: () => {
      return new Response("<div>hello world</div>", {
        headers: { "Content-Type": "text/html" },
      });
    },
  },
  {
    wsPath: "your_ws_path",
  }
);
