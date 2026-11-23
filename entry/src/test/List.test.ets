import localUnitTest from './LocalUnit.test';
import m1HelpersTest from './M1Helpers.test';
import m2HelpersTest from './M2Helpers.test';
import m3HelpersTest from './M3Helpers.test';

export default function testsuite() {
  localUnitTest();
  m1HelpersTest();
  m2HelpersTest();
  m3HelpersTest();
}
