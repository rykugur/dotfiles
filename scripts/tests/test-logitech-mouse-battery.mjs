import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { runInNewContext } from "node:vm";

const path = new URL("../../modules/nixos/_logitech/mouse-battery/Battery.js", import.meta.url);
const parseBattery = runInNewContext(readFileSync(path, "utf8") + "\nparseBattery;");

test("reads battery percentage rather than DPI or feature numbers", () => {
  assert.equal(parseBattery("Sensitivity (DPI): 2400\n  6: UNIFIED BATTERY {1004} V3\n     Battery: 76%, BatteryStatus.DISCHARGING.\n", 0), 76);
});

test("keeps genuine empty and full battery readings", () => {
  assert.equal(parseBattery(" Battery: 0%, BatteryStatus.DISCHARGING.", 0), 0);
  assert.equal(parseBattery(" Battery: 100%, BatteryStatus.FULL.", 0), 100);
});

test("does not turn missing or invalid readings into a battery value", () => {
  for (const output of ["", "Device is offline", "Battery: unknown", "Battery: 110%", "Battery: -1%", "Battery: 76.5%", "Sensitivity (DPI): 2400"]) {
    assert.equal(parseBattery(output, 0), null, output);
  }
});

test("discards output from a failed query instead of keeping a stale value", () => {
  assert.equal(parseBattery(" Battery: 76%, BatteryStatus.DISCHARGING.", 1), null);
});
