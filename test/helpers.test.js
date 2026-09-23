import test from "node:test";
import assert from "node:assert/strict";
import {
  buildTopicName,
  buildUserCard,
  clampInteger,
  escapeHtml,
  parseCommand,
  truncate
} from "../src/index.js";

test("parseCommand 支援 bot 後綴並忽略參數", () => {
  assert.equal(parseCommand("/BLOCK@MyBot now"), "block");
  assert.equal(parseCommand("一般訊息"), null);
});

test("buildTopicName 使用繁體中文名稱並限制長度", () => {
  const name = buildTopicName({ id: 123, first_name: "測".repeat(140) });
  assert.equal(Array.from(name).length, 128);
  assert.ok(name.endsWith("…"));
});

test("buildTopicName 移除換行與雙向控制字元", () => {
  const name = buildTopicName({ id: 123, first_name: "管理\n者\u202e假名" });
  assert.equal(name, "管理 者 假名 · 123");
});

test("buildUserCard 會跳脫 Telegram HTML", () => {
  const card = buildUserCard({ id: 123, first_name: "<測試>", username: "a&b" });
  assert.match(card, /&lt;測試&gt;/);
  assert.match(card, /@a&amp;b/);
  assert.doesNotMatch(card, /<測試>/);
});

test("escapeHtml 跳脫特殊字元", () => {
  assert.equal(escapeHtml('<a href="x">&'), "&lt;a href=&quot;x&quot;&gt;&amp;");
});

test("truncate 不拆散 Unicode 字元", () => {
  assert.equal(truncate("甲乙丙丁", 3), "甲乙…");
});

test("clampInteger 套用範圍與預設值", () => {
  assert.equal(clampInteger("99", 0, 60, 2), 60);
  assert.equal(clampInteger("bad", 0, 60, 2), 2);
});
