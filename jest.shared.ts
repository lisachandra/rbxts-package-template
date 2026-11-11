import { defineConfig } from "@isentinel/jest-roblox";

const isCi = process.env["CI"] !== undefined && process.env["CI"] !== "";

/*
 * Specs the emulator lane cannot run yet — ree parity gaps, each with a
 * captured failure signature in docs/agents/offline-runtime-spike.md.
 *
 * NOTE FOR AGENTS:
 * Implementing spec that fails on Roblox engine gap (ree parity)? Add the spec
 * path here with a one-line comment naming what ree does not do.
 */
const reeParityPaths: Array<string> = [];

export default defineConfig({
	/*
	 * Default lane: the emulator backend stages the compiled out/ tree and runs
	 * it inside ree — offline, no Studio roundtrip. Parity gaps are listed per
	 * package in docs/agents/offline-runtime-spike.md.
	 */
	backend: "emulator",
	emulator: {
		ignorePatterns: [...reeParityPaths],
		reePath: "ree",
		reflectionPath: "../../scripts/emulator/reflection.json",
		seconds: 30,
	},
	gameOutput: "game-output.log",
	jestPath: "ReplicatedStorage/TS/rbxts_include/node_modules/@rbxts/jest/src",
	outputFile: "jest-output.log",
	placeFile: "test.rbxl",
	test: {
		clearMocks: true,
		collectCoverage: true,
		coveragePathIgnorePatterns: ["**/*.spec.ts", "**/*.spec.tsx"],
		mockDataModel: false,
		runInBand: true,
		testTimeout: isCi ? 600_000 : 300_000,
	},
	timeout: isCi ? 600_000 : 300_000,
});
