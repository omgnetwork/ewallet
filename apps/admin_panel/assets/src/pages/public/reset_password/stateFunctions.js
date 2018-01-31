export function isEmailValid(state) {
  const { email } = state;
  return /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,})+$/.test(email);
}

export function getEmailValidationState(state) {
  const { submitted, didModifyEmail } = state;
  return !isEmailValid(state) && (submitted || didModifyEmail) ? 'error' : null;
}

export function isFormValid(state) {
  return isEmailValid(state);
}

export function onInputChange(target) {
  const { id, value } = target;
  return {
    [id]: value,
    didModifyEmail: true,
  };
}

export function onSubmit() {
  return { submitted: true };
}
