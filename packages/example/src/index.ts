/** Adds two numbers together. */
export function add(a: number, b: number): number {
	return a + b;
}

/** A small example type that demonstrates exporting types from the package. */
export interface ExampleOptions {
	readonly label: string;
}

/** Example constant exported from the package entry point. */
export const PACKAGE_NAME = "@lisachandra/example";
