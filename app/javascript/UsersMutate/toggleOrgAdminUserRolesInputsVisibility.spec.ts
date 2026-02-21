import { VANITA_VIEWER } from "UserRole";
import { toggleOrgAdminUserRolesInputsVisibility } from "./toggleOrgAdminUserRolesInputsVisibility";

type SetupOptions = {
  checkedValue?: string | null;
};

describe("toggleOrgAdminUserRolesInputsVisibility", () => {
  describe("when the global role input is initially unchecked", () => {
    it("hides the organization roles inputs element", () => {
      const { organizationRolesElement } = setup({ checkedValue: null });

      expectVisibility(organizationRolesElement, false);
    });

    it("shows the organization roles inputs element when the global role input is checked", () => {
      const { organizationRolesElement, selectValue } = setup({ checkedValue: null });

      selectValue("");

      expectVisibility(organizationRolesElement, true);
    });
  });

  describe("when the global role input is initially checked", () => {
    it("shows the organization roles inputs element", () => {
      const { organizationRolesElement } = setup({ checkedValue: VANITA_VIEWER });

      expectVisibility(organizationRolesElement, true);
    });

    it("hides the organization roles inputs element when the global role input is unchecked", () => {
      const { organizationRolesElement, selectValue } = setup({ checkedValue: VANITA_VIEWER });

      selectValue("org_admin");

      expectVisibility(organizationRolesElement, false);
    });
  });
});

function setup({ checkedValue }: SetupOptions) {
  document.body.innerHTML = `
    <div id="organization-roles"></div>
    <div id="inputs">
      <input type="radio" name="global_role" value="" />
      <input type="radio" name="global_role" value="${VANITA_VIEWER}" />
      <input type="radio" name="global_role" value="org_admin" />
    </div>
  `;

  const organizationRolesElement = document.getElementById("organization-roles") as HTMLElement;
  const globalRoleInputElement = document.querySelectorAll<HTMLInputElement>(
    "#inputs input[type='radio']"
  );

  if (checkedValue !== undefined && checkedValue !== null) {
    selectValue(globalRoleInputElement, checkedValue);
  }

  toggleOrgAdminUserRolesInputsVisibility({ organizationRolesElement, globalRoleInputElement });

  return {
    organizationRolesElement,
    selectValue: (value: string) => {
      selectValue(globalRoleInputElement, value);
    }
  };
}

function selectValue(inputs: NodeListOf<HTMLInputElement>, value: string) {
  inputs.forEach((input) => {
    input.checked = input.value === value;
  });
  inputs.forEach((input) => {
    input.dispatchEvent(new Event("change", { bubbles: true }));
  });
}

function expectVisibility(element: HTMLElement, expected: boolean) {
  const display = element.style.display;
  expect(display).toBe(expected ? "block" : "none");
}
