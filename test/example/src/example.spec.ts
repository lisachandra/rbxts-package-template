import { add } from "@lisachandra/example";
import { describe, expect, it } from "@rbxts/jest-globals";

describe("add", () => {
	it("should add two numbers", () => {
		expect.assertions(1);
		expect(add(1, 2)).toBe(3);
	});
});
