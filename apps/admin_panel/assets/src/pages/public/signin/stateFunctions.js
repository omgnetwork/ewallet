function isEmailValid(state) {
  const { email } = state;
  return /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,})+$/.test(email);
}

function isPasswordValid(state) {
  const { password } = state;
  return password.length >= 8;
}

export function getEmailValidationState(state) {
  const { submitted, didModifyEmail } = state;
  return !isEmailValid(state) && (submitted || didModifyEmail) ? 'error' : null;
}

export function getPasswordValidationState(state) {
  const { submitted, didModifyPassword } = state;
  return !isPasswordValid(state) && (submitted || didModifyPassword) ? 'error' : null;
}

export function isFormValid(state) {
  return isEmailValid(state) && isPasswordValid(state);
}

export function onInputChange(target, state) {
  const { id, value } = target;
  let { didModifyEmail, didModifyPassword } = state;
  if (id === 'email') {
    didModifyEmail = true;
  } else if (id === 'password') {
    didModifyPassword = true;
  }
  return {
    [id]: value,
    didModifyEmail,
    didModifyPassword,
  };
}

export function onSubmit() {
  return { submitted: true };
}
