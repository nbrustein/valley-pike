import { getDefaultPreferredName } from "./getDefaultPreferredName";

describe("getDefaultPreferredName", () => {
  let fullName: string;
  describe("with a western name", () => {
    beforeEach(() => {
      fullName = "John Doe";
    });

    it("returns the first name for a western name", () => {
      expect(getDefaultPreferredName("John Doe")).toBe("John");
    });
  });

  describe("with a chinese name", () => {
    beforeEach(() => {
      fullName = "张伟";
    });

    it("returns the full name for a chinese name", () => {
      expect(getDefaultPreferredName(fullName)).toBe(fullName);
    });
  });
});
