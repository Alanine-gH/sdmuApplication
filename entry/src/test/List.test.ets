import localUnitTest from './LocalUnit.test';
import m1HelpersTest from './M1Helpers.test';
import m2HelpersTest from './M2Helpers.test';

export default function testsuite() {
  localUnitTest();
  m1HelpersTest();
  m2HelpersTest();
}
