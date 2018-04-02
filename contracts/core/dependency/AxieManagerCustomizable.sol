pragma solidity ^0.4.19;


import "zeppelin/contracts/ownership/Ownable.sol";

import "./AxieManager.sol";


// solium-disable-next-line lbrace
contract AxieManagerCustomizable is
  AxieSpawningManager,
  AxieRetirementManager,
  AxieMarketplaceManager,
  AxieGeneManager,
  Ownable
{

  bool public allowedAll;

  function setAllowAll(bool _allowedAll) external onlyOwner {
    allowedAll = _allowedAll;
  }

  function isSpawningAllowed(uint256, address) external returns (bool) {
    return allowedAll;
  }

  function isRebirthAllowed(uint256, uint256) external returns (bool) {
    return allowedAll;
  }

  function isRetirementAllowed(uint256, bool) external returns (bool) {
    return allowedAll;
  }

  function isTransferAllowed(address, address, uint256) external returns (bool) {
    return allowedAll;
  }

  function isEvolvementAllowed(uint256, uint256) external returns (bool) {
    return allowedAll;
  }
}
