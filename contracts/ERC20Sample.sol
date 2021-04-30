pragma solidity ^0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ERC20Template is IERC20 {
    function mint(address account, uint256 amount) public {}

    function burn(address account, uint256 amount) public {}

    function redeem(address account, uint256 amount) public {}

    function issue(address account, uint256 amount) public {}
}
