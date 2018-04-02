pragma solidity ^0.4.19;


import "./AxiePausable.sol";


contract AxieUpgradeable is AxiePausable {

  address public newContractAddress;

  event ContractUpgraded(address _newAddress);

  function setNewAddress(address _newAddress) external onlyCEO whenPaused {
    newContractAddress = _newAddress;
    ContractUpgraded(_newAddress);
  }

  function unpause() public onlyCEO whenPaused {
    require(newContractAddress == address(0));
    super.unpause();
  }
}
