/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Ocaclize API interface
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock, Stephan Karpischek
 *
 * Hurricane Response with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity ^0.4.11;


import "./../vendors/usingOraclize.sol";

contract HurricaneResponseOraclizeInterface is usingOraclize {
  modifier onlyOraclizeOr (address _emergency) {
    require(msg.sender == oraclize_cbAddress() || msg.sender == _emergency);
    _;
  }
}
