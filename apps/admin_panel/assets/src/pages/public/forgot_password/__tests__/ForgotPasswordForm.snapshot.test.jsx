import renderer from 'react-test-renderer';
import ForgotPasswordForm from '../ForgotPasswordForm';
import { SnapshotComponentTester } from '../../../../../__tests__/ComponentTester';

it('renders correctly', () => {
  const forgotPassword = jest.fn();
  const onSuccess = jest.fn();
  const tree = renderer.create(SnapshotComponentTester(ForgotPasswordForm, {
    loading: false, forgotPassword, onSuccess,
  })).toJSON();
  expect(tree).toMatchSnapshot();
});
