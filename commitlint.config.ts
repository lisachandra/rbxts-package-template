import type { UserConfig } from "@commitlint/types";

const commitLintConfig: UserConfig = {
	"body-max-length": 10000,
	"body-max-line-length": 10000,
	"extends": ["@commitlint/config-conventional"],
	"footer-max-length": 10000,
	"footer-max-line-length": 10000,
	"header-max-length": 10000,
	"scope-max-length": 10000,
	"subject-max-length": 10000,
	"type-max-length": 10000,
};

export default commitLintConfig;
