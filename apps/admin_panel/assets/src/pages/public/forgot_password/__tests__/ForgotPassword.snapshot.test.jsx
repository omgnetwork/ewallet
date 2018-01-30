import renderer from 'react-test-renderer';
import ForgotPassword from '../ForgotPassword';
import { SnapshotComponentTester } from '../../../../../__tests__/ComponentTester';

it('renders correctly', () => {
  const tree = renderer.create(SnapshotComponentTester(ForgotPassword, {})).toJSON();
  expect(tree).toMatchSnapshot();
});
