import { getDefaultPreferredName } from "./getDefaultPreferredName";

type Inputs = {
  fullNameInputElement: HTMLInputElement | null;
  preferredNameInputElement: HTMLInputElement | null;
};

/*
  As long as the preferred name input is empty or equal to the default,
  update the preferred name input automatically when the full name input is updated.

  Once the preferred name input is updated to be different, stop updating preferred name 
  automatically.

  If either the full name input or the preferred name input is updated such that the 
  preferred name is once again equal to the default, being auto-syncing again.
*/
export function syncPreferredName({ fullNameInputElement, preferredNameInputElement }: Inputs) {
  if (!fullNameInputElement || !preferredNameInputElement) return;

  const getUseDefaultPreferredName = () => {
    const fullName = fullNameInputElement.value;
    const preferredName = preferredNameInputElement.value;
    return preferredName.length === 0 || preferredName === getDefaultPreferredName(fullName);
  };

  let useDefaultPreferredName = getUseDefaultPreferredName();

  fullNameInputElement.addEventListener("input", () => {
    const fullName = fullNameInputElement.value;
    if (useDefaultPreferredName) {
      preferredNameInputElement.value = getDefaultPreferredName(fullName);
    }
    useDefaultPreferredName = getUseDefaultPreferredName();
  });

  preferredNameInputElement.addEventListener("input", () => {
    useDefaultPreferredName = getUseDefaultPreferredName();
  });
}
