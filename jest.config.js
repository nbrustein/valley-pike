module.exports = {
  preset: "ts-jest",
  testEnvironment: "jsdom",
  roots: ["<rootDir>/app/javascript"],
  testMatch: ["**/*.spec.ts", "**/*.test.ts"],
  moduleDirectories: ["node_modules", "app/javascript"],
  setupFilesAfterEnv: ["<rootDir>/jest.setup.ts"],
  transform: {
    "^.+\\.ts$": ["ts-jest", { tsconfig: "tsconfig.jest.json" }]
  }
};
