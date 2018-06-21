/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description Controlled contract Interface
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


import "./HurricaneGuardControllerInterface.sol";
import "./HurricaneGuardDatabaseModel.sol";


contract HurricaneGuardControlledContract is HurricaneGuardDatabaseModel {
  address public controller;
  HurricaneGuardControllerInterface internal HG_CI;

  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }

  function destruct() public onlyController {
    selfdestruct(controller);
  }

  // solhint-disable-next-line no-empty-blocks
  function setContracts() public onlyController {}

  function getContract(bytes32 _id) internal returns (address _addr) {
    _addr = HG_CI.getContract(_id);
  }

  function setController(address _controller) internal returns (bool _result) {
    controller = _controller;
    HG_CI = HurricaneGuardControllerInterface(_controller);
    _result = true;
  }
}
