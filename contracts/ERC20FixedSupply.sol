pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


//固定总量代币
contract ERC20FixedSupply is ERC20,Ownable {
    constructor(
        string memory name, //代币名称
        string memory symbol, //代币缩写
        uint256 totalSupply //发行总量
    ) public ERC20(name, symbol) {
        _mint(msg.sender, totalSupply * 10**18);
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }
}
