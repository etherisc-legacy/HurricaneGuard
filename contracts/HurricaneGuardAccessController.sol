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


import "./HurricaneGuardControlledContract.sol";
import "./HurricaneGuardDatabaseInterface.sol";
import "./HurricaneGuardConstants.sol";

contract HurricaneGuardAccessController is HurricaneGuardControlledContract, HurricaneGuardConstants {
  HurricaneGuardDatabaseInterface HG_DB;

  modifier onlyEmergency() {
    require(msg.sender == HG_CI.getContract('HG.Emergency'));
    _;
  }

  function HurricaneGuardAccessController(address _controller) {
    setController(_controller);
  }

  function setContracts() onlyController {
    HG_DB = HurricaneGuardDatabaseInterface(getContract("HG.Database"));
  }

  function setPermissionById(uint8 _perm, bytes32 _id) {
    HG_DB.setAccessControl(msg.sender, HG_CI.getContract(_id), _perm);
  }

  function fixPermission(address _target, address _accessor, uint8 _perm, bool _access) onlyEmergency {
    HG_DB.setAccessControl(
      _target,
      _accessor,
      _perm,
      _access
    );
  }

  function setPermissionById(uint8 _perm, bytes32 _id, bool _access) {
    HG_DB.setAccessControl(
      msg.sender,
      HG_CI.getContract(_id),
      _perm,
      _access
    );
  }

  function setPermissionByAddress(uint8 _perm, address _addr) {
    HG_DB.setAccessControl(msg.sender, _addr, _perm);
  }

  function setPermissionByAddress(uint8 _perm, address _addr, bool _access) {
    HG_DB.setAccessControl(
      msg.sender,
      _addr,
      _perm,
      _access
    );
  }

  function checkPermission(uint8 _perm, address _addr) returns (bool _success) {
    _success = HG_DB.getAccessControl(msg.sender, _addr, _perm);
  }
}
