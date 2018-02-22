function isSymbolValid(state) {
  const { symbol } = state;
  return symbol.length >= 3;
}

function isNameValid(state) {
  const { name } = state;
  return name.length >= 3;
}

function isSubunitToUnitValid(state) {
  const { subUnitToUnit } = state;
  return subUnitToUnit.length >= 1;
}

export function getValidationState(field, state) {
  const {
    submitted,
    didModifySymbol,
    didModifyName,
    didModifySubunitToUnit,
  } = state;
  switch (field) {
    case 'symbol':
      return !isSymbolValid(state) && (submitted || didModifySymbol) ? 'error' : null;
    case 'name':
      return !isNameValid(state) && (submitted || didModifyName) ? 'error' : null;
    case 'subUnitToUnit':
      return !isSubunitToUnitValid(state) && (submitted || didModifySubunitToUnit) ? 'error' : null;
    default:
      return null;
  }
}

export function isFormValid(state) {
  return isSymbolValid(state) && isNameValid(state) && isSubunitToUnitValid(state);
}

export function onInputChange(target, state) {
  const { id, value } = target;
  let { didModifySymbol, didModifyName, didModifySubunitToUnit } = state;
  switch (id) {
    case 'symbol':
      didModifySymbol = true;
      break;
    case 'name':
      didModifyName = true;
      break;
    case 'subUnitToUnit':
      didModifySubunitToUnit = true;
      break;
    default:
      break;
  }
  return {
    [id]: value,
    didModifySymbol,
    didModifyName,
    didModifySubunitToUnit,
  };
}

export function onCheckChange(target) {
  const { id, checked } = target;
  return {
    [id]: checked,
  };
}

export function onSubmit() {
  return { submitted: true };
}
