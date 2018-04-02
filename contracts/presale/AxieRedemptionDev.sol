pragma solidity ^0.4.19;


import "oraclize-api/contracts/usingOraclize.sol";

import "./AxieRedemptionInternal.sol";


contract AxieRedemptionDev is AxieRedemptionInternal, usingOraclize {
  function _startTimestamp() internal returns (uint256) {
    return 0;
  }

  function _sendRandomQuery(uint256 _gasLimit) internal returns (uint256) {
    return uint256(oraclize_query("WolframAlpha", "random number between 1 and 2^64", _gasLimit));
  }

  // solium-disable-next-line function-order, mixedcase
  function __callback(bytes32 _queryId, string _result) public {
    require(msg.sender == oraclize_cbAddress());
    _receiveRandomQuery(uint256(_queryId), _result);
  }
}
