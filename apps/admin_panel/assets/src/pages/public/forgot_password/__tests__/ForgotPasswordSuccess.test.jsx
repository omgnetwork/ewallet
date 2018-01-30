import Enzyme from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
import { createMemoryHistory } from 'history';
import ForgotPasswordSuccess from '../ForgotPasswordSuccess';
import { ShallowComponentTester } from '../../../../../__tests__/ComponentTester';

Enzyme.configure({ adapter: new Adapter() });

describe('ForgotPasswordSuccess', () => {
  test('redirect to signin on click', () => {
    const history = createMemoryHistory();
    // Note that the shallow rendering doesn't let us access to the props initially
    // passed (in our case history and translate). To be able to test the redirect
    // we need to hold a reference to `history`.
    const component = ShallowComponentTester(ForgotPasswordSuccess, { history });
    expect(history.location.pathname).toBe('/');
    component.find('Button').at(0).simulate('click');
    expect(history.location.pathname).toBe('/signin');
  });
});
