pragma solidity ^0.4.19;


contract AxieAccessControl {

  address public ceoAddress;
  address public cfoAddress;
  address public cooAddress;

  function AxieAccessControl() internal {
    ceoAddress = msg.sender;
  }

  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

  modifier onlyCLevel() {
    require(
      // solium-disable operator-whitespace
      msg.sender == ceoAddress ||
        msg.sender == cfoAddress ||
        msg.sender == cooAddress
      // solium-enable operator-whitespace
    );
    _;
  }

  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

  function setCFO(address _newCFO) external onlyCEO {
    cfoAddress = _newCFO;
  }

  function setCOO(address _newCOO) external onlyCEO {
    cooAddress = _newCOO;
  }

  function withdrawBalance() external onlyCFO {
    cfoAddress.transfer(this.balance);
  }
}
