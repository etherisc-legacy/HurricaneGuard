/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	AccessControllerInterface
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 *
 * HurricaneGuard with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity ^0.4.11;


contract HurricaneGuardAccessControllerInterface {
  function setPermissionById(uint8 _perm, bytes32 _id);

  function setPermissionById(uint8 _perm, bytes32 _id, bool _access);

  function setPermissionByAddress(uint8 _perm, address _addr);

  function setPermissionByAddress(uint8 _perm, address _addr, bool _access);

  function checkPermission(uint8 _perm, address _addr) returns (bool _success);
}
