import { toggleDriverQualificationInputs } from "./toggleDriverQualificationInputs";

describe("toggleDriverQualificationInputs", () => {
  describe("when the driver role input is initially unchecked", () => {
    it("disables the qualification inputs and clears selections", () => {
      const { qualificationInputs } = setup({ checked: false, qualificationChecked: true });

      qualificationInputs.forEach((input) => {
        expect(input.disabled).toBe(true);
        expect(input.checked).toBe(false);
      });
    });

    it("enables the qualification inputs when the driver role input is checked", () => {
      const { qualificationInputs, toggleDriver } = setup({ checked: false });

      toggleDriver(true);

      qualificationInputs.forEach((input) => {
        expect(input.disabled).toBe(false);
      });
    });
  });

  describe("when the driver role input is initially checked", () => {
    it("enables the qualification inputs", () => {
      const { qualificationInputs } = setup({ checked: true });

      qualificationInputs.forEach((input) => {
        expect(input.disabled).toBe(false);
      });
    });
  });
});

type SetupOptions = {
  checked: boolean;
  qualificationChecked?: boolean;
};

function setup({ checked, qualificationChecked = false }: SetupOptions) {
  document.body.innerHTML = `
    <input type="checkbox" id="driver-role" />
    <input type="checkbox" id="qualification-1" />
    <input type="checkbox" id="qualification-2" />
  `;

  const driverRoleInputElement = document.getElementById("driver-role") as HTMLInputElement;
  const qualificationInputs = document.querySelectorAll<HTMLInputElement>(
    "#qualification-1, #qualification-2"
  );

  driverRoleInputElement.checked = checked;
  qualificationInputs.forEach((input) => {
    input.checked = qualificationChecked;
  });

  toggleDriverQualificationInputs({
    driverRoleInputElement,
    driverQualificationInputElements: qualificationInputs
  });

  return {
    qualificationInputs,
    toggleDriver: (value: boolean) => {
      driverRoleInputElement.checked = value;
      driverRoleInputElement.dispatchEvent(new Event("change", { bubbles: true }));
    }
  };
}
