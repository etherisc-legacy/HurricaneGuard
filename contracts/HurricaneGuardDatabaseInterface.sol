/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description Database contract interface
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock, Stephan Karpischek
 *
 * HurricaneGuard with Underwriting and Payout
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */


pragma solidity 0.4.21;


import "./HurricaneGuardDatabaseModel.sol";


contract HurricaneGuardDatabaseInterface is HurricaneGuardDatabaseModel {
  function createPolicy(
    address _customer,
    uint _premium,
    Currency _currency,
    bytes32 _customerExternalId,
    bytes32 _riskId,
    bytes32 _latlng
  ) public returns (uint _policyId);

  function createOraclizeCallback(
    bytes32 _queryId,
    uint _policyId,
    OraclizeState _oraclizeState
  ) public;

  function setAccessControl(address _contract, address _caller, uint8 _perm) public;

  function setAccessControl(
    address _contract,
    address _caller,
    uint8 _perm,
    bool _access
  ) public;

  function getAccessControl(address _contract, address _caller, uint8 _perm) public returns (bool _allowed);

  function setLedger(uint8 _index, int _value) public;

  function getLedger(uint8 _index) public returns (int _value);

  function getCustomerPremium(uint _policyId) public returns (address _customer, uint _premium);

  function getPolicyData(
    uint _policyId
  ) public returns (address _customer, uint _premium, uint _weight, bytes32 _latlng);

  function getPolicyState(uint _policyId) public returns (PolicyState _state);

  function getRiskId(uint _policyId) public returns (bytes32 _riskId);

  function setState(
    uint _policyId,
    PolicyState _state,
    uint _stateTime,
    bytes32 _stateMessage
  ) public;

  function setWeight(uint _policyId, uint _weight, bytes _proof) public;

  function setPayouts(uint _policyId, uint _calculatedPayout, uint _actualPayout) public;

  function setHurricaneCategory(uint _policyId, bytes32 _category) public;

  function getRiskParameters(bytes32 _riskId) public returns (bytes32 _market, bytes32 _season);

  function getPremiumFactors(bytes32 _riskId)
    public returns (uint _cumulatedWeightedPremium, uint _premiumMultiplier);

  function createUpdateRisk(bytes32 _market, bytes32 _season) public returns (bytes32 _riskId);

  function setPremiumFactors(bytes32 _riskId, uint _cumulatedWeightedPremium, uint _premiumMultiplier) public;

  function getOraclizeCallback(bytes32 _queryId) public returns (uint _policyId);

  function getOraclizePolicyId(bytes32 _queryId) public returns (uint _policyId);
}
