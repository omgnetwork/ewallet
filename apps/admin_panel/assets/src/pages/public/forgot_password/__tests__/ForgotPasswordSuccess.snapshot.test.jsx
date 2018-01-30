import renderer from 'react-test-renderer';
import ForgotPasswordSuccess from '../ForgotPasswordSuccess';
import { SnapshotComponentTester } from '../../../../../__tests__/ComponentTester';

it('renders correctly', () => {
  const tree =
  renderer.create(SnapshotComponentTester(ForgotPasswordSuccess)).toJSON();
  expect(tree).toMatchSnapshot();
});
