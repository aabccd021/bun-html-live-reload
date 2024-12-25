import { afterEach, expect, test } from "bun:test";
import { copyFileSync, mkdtempSync } from "node:fs";
import { chromium } from "playwright";

const serverCodeInit = `
import { withHtmlLiveReload } from "./bun-html-live-reload.ts";

Bun.serve({
  fetch: withHtmlLiveReload(async () => {
    return new Response("<div>Init</div>", {
      headers: { "Content-Type": "text/html" },
    });
  }, { autoReload: false })
});
`;

const serverCodeChanged = `
import { withHtmlLiveReload } from "./bun-html-live-reload.ts";
Bun.serve({
  fetch: withHtmlLiveReload(async () => {
    return new Response("<div>Changed</div>", {
      headers: { "Content-Type": "text/html" },
    }),
  }, { autoReload: false })
});
`;

let close: () => Promise<void> | undefined;

afterEach(async () => {
  await close?.();
});

test("can disable auto reload", async () => {
  const systemTmp = process.env["TMPDIR"] ?? "/tmp";
  const tmpdir = mkdtempSync(`${systemTmp}/bun-`);
  const serverPath = `${tmpdir}/server.ts`;
  const libPath = `${tmpdir}/bun-html-live-reload.ts`;

  await Bun.write(serverPath, serverCodeInit);

  copyFileSync(`${import.meta.dir}/index.ts`, libPath);

  const child = Bun.spawn(["bun", "--hot", serverPath], { stderr: "ignore" });

  const browser = await chromium.launch();

  close = async (): Promise<void> => {
    child?.kill();
    await browser.close();
  };

  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto("http://localhost:3000");

  expect(await page.innerText("div")).toBe("Init");

  await Bun.write(serverPath, serverCodeChanged);
  await new Promise((resolve) => setTimeout(resolve, 1000));

  expect(await page.innerText("div")).toBe("Init");
});
