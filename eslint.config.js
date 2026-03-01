const js = require("@eslint/js");
const globals = require("globals");
const tsParser = require("@typescript-eslint/parser");
const tsPlugin = require("@typescript-eslint/eslint-plugin");

module.exports = [
  {
    ignores: ["app/assets/builds/**"]
  },
  {
    files: ["app/javascript/**/*.{js,ts}"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      parser: tsParser,
      globals: globals.browser
    },
    plugins: {
      "@typescript-eslint": tsPlugin
    },
    rules: {
      ...js.configs.recommended.rules,
      ...tsPlugin.configs.recommended.rules,
      "no-undef": "off",
      "no-console": ["error", { allow: ["warn", "error"] }]
    }
  },
  {
    files: ["app/javascript/**/*.spec.ts", "app/javascript/**/*.test.ts"],
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.jest
      }
    },
    rules: {
      "no-restricted-globals": [
        "error",
        { name: "fit", message: "Do not use fit. Use it instead." },
        { name: "fdescribe", message: "Do not use fdescribe. Use describe instead." }
      ]
    }
  }
];
