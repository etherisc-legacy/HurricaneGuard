/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description Controlled contract Interface
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 *
 * Hurricane Response with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity ^0.4.11;


import "./HurricaneResponseControllerInterface.sol";
import "./HurricaneResponseDatabaseModel.sol";

contract HurricaneResponseControlledContract is HurricaneResponseDatabaseModel {
  address public controller;
  HurricaneResponseControllerInterface HR_CI;

  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }

  function setController(address _controller) internal returns (bool _result) {
    controller = _controller;
    HR_CI = HurricaneResponseControllerInterface(_controller);
    _result = true;
  }

  function destruct() onlyController {
    selfdestruct(controller);
  }

  function setContracts() onlyController {}

  function getContract(bytes32 _id) internal returns (address _addr) {
    _addr = HR_CI.getContract(_id);
  }
}
