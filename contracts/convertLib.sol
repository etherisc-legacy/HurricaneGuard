/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Conversions
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 *
 * HurricaneGuard with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity 0.4.21;


contract ConvertLib {

  // For date-time lib function getYear
  uint16 internal constant ORIGIN_YEAR = 1970;
  uint internal constant YEAR_IN_SECONDS = 31536000;
  uint internal constant LEAP_YEAR_IN_SECONDS = 31622400;

  // .. since beginning of the year
  uint16[12] internal days_since = [
    11,
    42,
    70,
    101,
    131,
    162,
    192,
    223,
    254,
    284,
    315,
    345
  ];

  function b32toHexString(bytes32 x) internal pure returns (string) {
    bytes memory b = new bytes(64);
    for (uint i = 0; i < 32; i++) {
      uint8 by = uint8(uint(x) / (2**(8*(31 - i))));
      uint8 high = by/16;
      uint8 low = by - 16*high;
      if (high > 9) {
        high += 39;
      }
      if (low > 9) {
        low += 39;
      }
      b[2*i] = byte(high+48);
      b[2*i+1] = byte(low+48);
    }

    return string(b);
  }

  // helper functions for getYear
  function isLeapYear(uint16 year) internal pure returns (bool) {
    if (year % 4 != 0) {
      return false;
    }
    if (year % 100 != 0) {
      return true;
    }
    if (year % 400 != 0) {
      return false;
    }
    return true;
  }

  function leapYearsBefore(uint year) internal pure returns (uint) {
    year -= 1;
    return year / 4 - year / 100 + year / 400;
  }

  function getYear(uint timestamp) internal pure returns (uint16) {
    uint secondsAccountedFor = 0;
    uint16 year;
    uint numLeapYears;

    // Year
    year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
    numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
    secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

    while (secondsAccountedFor > timestamp) {
      if (isLeapYear(uint16(year - 1))) {
        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
      } else {
        secondsAccountedFor -= YEAR_IN_SECONDS;
      }
      year -= 1;
    }
    return year;
  }

  function stringToBytes32(string memory _source) internal pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(_source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    /* solhint-disable no-inline-assembly */
    assembly {
      result := mload(add(_source, 32))
    }
    /* solhint-enable no-inline-assembly */
  }

  function b32toString(bytes32 x) internal pure returns (string) {
    // gas usage: about 1K gas per char.
    bytes memory bytesString = new bytes(32);
    uint charCount = 0;

    for (uint j = 0; j < 32; j++) {
      byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
      if (char != 0) {
        bytesString[charCount] = char;
        charCount++;
      }
    }

    bytes memory bytesStringTrimmed = new bytes(charCount);

    for (j = 0; j < charCount; j++) {
      bytesStringTrimmed[j] = bytesString[j];
    }

    return string(bytesStringTrimmed);
  }
}
