import { syncPreferredName } from "./syncPreferredName";

describe("syncPreferredName", () => {
  let setFullName: (value: string) => void;
  let preferredNameInputElement: HTMLInputElement;
  let setPreferredName: (value: string) => void;
  let fullNameInputElement: HTMLInputElement;

  describe("when initial values are empty", () => {
    beforeEach(() => ({ setFullName, preferredNameInputElement } = setup()))

    it("sets preferred name to default when full name is updated", () => {
      setFullName("John Doe");
      expect(preferredNameInputElement.value).toBe("John");
    });
  });

  describe("when initial preferred name is equal to the default", () => {
    beforeEach(() => ({ setFullName, preferredNameInputElement, setPreferredName } = setup({
      fullName: "John Doe",
      preferredName: "John",
    })))

    it("sets preferred name to default when full name is updated", () => {
      setFullName("John Smith");
      expect(preferredNameInputElement.value).toBe("John");
    });

    it("does not change preferred name when preferred name is updated and then full name is updated", () => {
      setPreferredName("Johnny");
      setFullName("John Smith");
      expect(preferredNameInputElement.value).toBe("Johnny");
    });
  });

  describe("when initial preferred name is not equal to the default", () => {
    const initialPreferredName = "JD";
    const initialFullName = "John Doe";
    beforeEach(() => ({ setPreferredName, preferredNameInputElement, fullNameInputElement, setFullName } = setup({
      fullName: initialFullName,
      preferredName: initialPreferredName,
    })))

    it("allows updates to preferred name input", () => {
      setPreferredName("J.D.");
      expect(preferredNameInputElement.value).toBe("J.D.");
      expect(fullNameInputElement.value).toBe(initialFullName);
    });

    it("does not change preferred name when full name input is updated", () => {
      setFullName("John Smith");
      expect(preferredNameInputElement.value).toBe(initialPreferredName);
    });

    describe("when full name input is updated such that preferred name is once again equal to the default", () => {
      beforeEach(() => {
        setFullName("JD Smith");
      });
      it("sets preferred name to default when full name input is updated again", () => {
        setFullName("Jane Doe");
        expect(preferredNameInputElement.value).toBe("Jane");
      });
    });

    describe("when preferred name input is updated such that preferred name is once again equal to the default", () => {
      beforeEach(() => {
        setPreferredName("John");
      });
      it("sets preferred name to default when full name input is updated again", () => {
        setFullName("Fred Smith");

        expect(preferredNameInputElement.value).toBe("Fred");
      });
    });
  });
});

type SetupOptions = {
  fullName?: string;
  preferredName?: string;
};

function setup({ fullName = "", preferredName = "" }: SetupOptions = {}) {
  document.body.innerHTML = `
    <input id="full-name" type="text" />
    <input id="preferred-name" type="text" />
  `;

  const fullNameInputElement = document.getElementById("full-name") as HTMLInputElement;
  const preferredNameInputElement = document.getElementById("preferred-name") as HTMLInputElement;

  fullNameInputElement.value = fullName;
  preferredNameInputElement.value = preferredName;

  syncPreferredName({ fullNameInputElement, preferredNameInputElement });

  return {
    preferredNameInputElement,
    fullNameInputElement,
    setFullName: (value: string) => {
      fullNameInputElement.value = value;
      fullNameInputElement.dispatchEvent(new Event("input", { bubbles: true }));
    },
    setPreferredName: (value: string) => {
      preferredNameInputElement.value = value;
      preferredNameInputElement.dispatchEvent(new Event("input", { bubbles: true }));
    },
  };
}
