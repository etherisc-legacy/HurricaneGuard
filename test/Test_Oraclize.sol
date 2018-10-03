/**
 * FlightDelay with Oraclized Underwriting and Payout
 *
 * @description	Payout contract
 * @copyright (c) 2017 etherisc GmbH
 * @author Christoph Mussenbrock
 *
 * HurricaneGuard
 * Modified work
 *
 * @copyright (c) 2018 Joel Martínez
 * @author Joel Martínez
 */

pragma solidity 0.4.24;


import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/HurricaneGuardOraclizeInterface.sol";


contract Test_Oraclize is HurricaneGuardOraclizeInterface {
	bytes32 queryId;
  event LogBytes32(string _message, bytes32 hexBytes32);
  event LogBytes(string _message, bytes hexBytes);
  event LogString(string _message, string _string);

	function Test_Oraclize () public payable {}

	function test_call_it() public {
		queryId = oraclize_query(
			"URL",
			"json(https://api.weather.gov/stations/TJSJ/observations?limit=1).features[0].properties.windSpeed.value"
		);

		emit LogBytes32('queryId', queryId);
    Assert.equal(true, queryId != "", "query id should not be empty");
	}

	function __callback(bytes32 _queryId, string _result, bytes _proof) public {
		emit LogBytes32('queryId', _queryId);
		emit LogString('_result', _result);
		emit LogBytes('_proof', _proof);
	} // __callback
}
