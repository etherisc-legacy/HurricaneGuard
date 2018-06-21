/*
  Copyright (c) 2015-2016 Oraclize SRL
  Copyright (c) 2016 Oraclize LTD
*/


pragma solidity 0.4.21;


contract HurricaneGuardAddressResolver {
  address public addr;

  address public owner;

  function HurricaneGuardAddressResolver() public {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    require(msg.sender == owner);
    owner = _owner;
  }

  function getAddress() public constant returns (address _addr) {
    return addr;
  }

  function setAddress(address _addr) public {
    require(msg.sender == owner);
    addr = _addr;
  }
}
