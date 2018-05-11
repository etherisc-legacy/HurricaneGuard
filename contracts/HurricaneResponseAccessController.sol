/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Access controller
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


import "./HurricaneResponseControlledContract.sol";
import "./HurricaneResponseDatabaseInterface.sol";
import "./HurricaneResponseConstants.sol";

contract HurricaneResponseAccessController is HurricaneResponseControlledContract, HurricaneResponseConstants {
  HurricaneResponseDatabaseInterface HR_DB;

  modifier onlyEmergency() {
    require(msg.sender == HR_CI.getContract('HR.Emergency'));
    _;
  }

  function HurricaneResponseAccessController(address _controller) {
    setController(_controller);
  }

  function setContracts() onlyController {
    HR_DB = HurricaneResponseDatabaseInterface(getContract("HR.Database"));
  }

  function setPermissionById(uint8 _perm, bytes32 _id) {
    HR_DB.setAccessControl(msg.sender, HR_CI.getContract(_id), _perm);
  }

  function fixPermission(address _target, address _accessor, uint8 _perm, bool _access) onlyEmergency {
    HR_DB.setAccessControl(
      _target,
      _accessor,
      _perm,
      _access
    );
  }

  function setPermissionById(uint8 _perm, bytes32 _id, bool _access) {
    HR_DB.setAccessControl(
      msg.sender,
      HR_CI.getContract(_id),
      _perm,
      _access
    );
  }

  function setPermissionByAddress(uint8 _perm, address _addr) {
    HR_DB.setAccessControl(msg.sender, _addr, _perm);
  }

  function setPermissionByAddress(uint8 _perm, address _addr, bool _access) {
    HR_DB.setAccessControl(
      msg.sender,
      _addr,
      _perm,
      _access
    );
  }

  function checkPermission(uint8 _perm, address _addr) returns (bool _success) {
    _success = HR_DB.getAccessControl(msg.sender, _addr, _perm);
  }
}
