import { createMemoryHistory } from 'history';
import ResetPasswordSuccess from '../ResetPasswordSuccess';
import { ShallowComponentTester } from '../../../../../__tests__/ComponentTester';

describe('ResetPasswordSuccess', () => {
  test('redirect to signin on click', () => {
    const history = createMemoryHistory();
    // Note that the shallow rendering doesn't let us access to the props initially
    // passed (in our case history and translate). To be able to test the redirect
    // we need to hold a reference to `history`.
    const component = ShallowComponentTester(ResetPasswordSuccess, { history });
    expect(history.location.pathname).toBe('/');
    component.find('Button').at(0).simulate('click');
    expect(history.location.pathname).toBe('/signin');
  });
});
