
pragma solidity ^0.7.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol"
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Container.sol";
import "./BridgeStorage.sol";
import "./BridgeAdmin.sol";
import "./BridgeLogic.sol";
import "./ERC20Sample.sol";
import "./Bridge.sol";

contract Bridge is BridgeAdmin, Pausable {

    using SafeMath for uint256;

    string public constant name = "Bridge";

    BridgeLogic private logic;

    event DepositNative(address indexed from, uint256 value, string targetAddress, string chain);
    event DepositToken(address indexed from, uint256 value, address indexed token, string targetAddress, string chain, uint256 nativeValue);
    event WithdrawingNative(address indexed to, uint256 value, string proof);
    event WithdrawingToken(address indexed to, address indexed token, uint256 value, string proof);
    event WithdrawDoneNative(address indexed to, uint256 value, string proof);
    event WithdrawDoneToken(address indexed to, address indexed token, uint256 value, string proof);

    modifier onlyOperator() {
        require(itemAddressExists(OPERATORHASH, msg.sender), "wrong operator");
        _;
    }

    modifier onlyPauser() {
        require(itemAddressExists(PAUSERHASH, msg.sender), "wrong pauser");
        _;
    }

    modifier positiveValue(uint _value) {
        require(_value > 0, "value need > 0");
        _;
    }


    constructor(address[] memory _owners, uint _ownerRequired) {
        initAdmin(_owners, _ownerRequired);

    }

    function depositNative(string memory _targetAddress, string memory  chain) public payable {
        emit DepositNative(msg.sender, msg.value, _targetAddress,chain);
    }

    function depositToken(address _token, uint value, string memory _targetAddress, string memory chain) public payable returns (bool){
        //deposit(address token, address _from, uint256 _value)
        bool res = depositTokenLogic(_token,  msg.sender, value);
        emit DepositToken(msg.sender, value, _token, _targetAddress, chain, msg.value);
        return res;
    }// 

    function withdrawNative(address payable to, uint value, string memory proof, bytes32 taskHash) public
    onlyOperator
    whenNotPaused
    positiveValue(value)
    returns(bool)
    {
        require(address(this).balance >= value, "not enough native token");
        require(taskHash == keccak256((abi.encodePacked(to,value,proof))),"taskHash is wrong");
        uint256 status = logic.supportTask(logic.WITHDRAWTASK(), taskHash, msg.sender, operatorRequireNum);

        if (status == logic.TASKPROCESSING()){
            emit WithdrawingNative(to, value, proof);
        }else if (status == logic.TASKDONE()) {
            emit WithdrawingNative(to, value, proof);
            emit WithdrawDoneNative(to, value, proof);
            to.transfer(value);
            logic.removeTask(taskHash);
        }
        return true;
    }

    function withdrawToken(address _token, address to, uint value, string memory proof, bytes32 taskHash) public
    onlyOperator
    whenNotPaused
    positiveValue(value)
    returns (bool)
    {
        require(taskHash == keccak256((abi.encodePacked(to,value,proof))),"taskHash is wrong");
        uint256 status = logic.supportTask(logic.WITHDRAWTASK(), taskHash, msg.sender, operatorRequireNum);

        if (status == logic.TASKPROCESSING()){
            emit WithdrawingToken(to, _token, value, proof);
        }else if (status == logic.TASKDONE()) {
            // withdraw(address token, address _to, address _value)
            bool res = withdrawTokenLogic( _token, to, value);

            emit WithdrawingToken(to, _token, value, proof);
            emit WithdrawDoneToken(to, _token, value, proof);
            logic.removeTask(taskHash);
            return res;
        }
        return true;
    }

    function modifyAdminAddress(string memory class, address oldAddress, address newAddress) public whenPaused {
        require(newAddress != address(0x0), "wrong address");
        bool flag = modifyAddress(class, oldAddress, newAddress);
        if(flag){
            bytes32 classHash = keccak256(abi.encodePacked(class));
            if(classHash == LOGICHASH){
                logic = BridgeLogic(newAddress);
            }else if(classHash == STOREHASH){
                logic.resetStoreLogic(newAddress);
            }
        }
    }
    function getLogicAddress() public view returns(address){
        return address(logic);
    }

    function getStoreAddress() public view returns(address){
        return logic.getStoreAddress();
    }

    function pause() public onlyPauser {
        _pause();
    }

    function unpause() public onlyPauser {
        _unpause();
    }


    function transferToken(address token, address to , uint256 value) onlyPauser external{
        IERC20 atoken = IERC20(token);
        bool success = atoken.transfer(to,value);
    }


    function setDepositSelector(address token, string memory method, bool _isValueFirst) onlyOperator external{
        depositSelector[token] = assetSelector(method,_isValueFirst);
    }

    function setWithdrawSelector(address token, string memory method, bool _isValueFirst) onlyOperator external{
        withdrawSelector[token] = assetSelector(method,_isValueFirst);
    }


    struct assetSelector{
        string selector;
        bool isValueFirst;
    }

    mapping (address=>assetSelector)  public depositSelector;
    mapping (address=> assetSelector) public withdrawSelector;

    function depositTokenLogic(address token, address _from, uint256 _value) internal returns(bool){
        bool status = false;
        bytes memory returnedData;
        if (bytes(depositSelector[token].selector).length == 0){
            (status,returnedData)= token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",_from,this,_value));
        }
        else{
            assetSelector memory aselector = depositSelector[token];
            if (aselector.isValueFirst){
                (status, returnedData) = token.call(abi.encodeWithSignature(aselector.selector,_value,_from));
            }
            else {
                (status,returnedData)= token.call(abi.encodeWithSignature(aselector.selector,_from,_value));
            }
        }
        require(
            status && (returnedData.length == 0 || abi.decode(returnedData, (bool))),
            ' transfer failed');
        return true;
    }

    function withdrawTokenLogic(address token, address _to, uint256 _value) internal returns(bool){
        bool status = false;
        bytes memory returnedData;
        if (bytes(withdrawSelector[token].selector).length==0){
            (status,returnedData)= token.call(abi.encodeWithSignature("transfer(address,uint256)",_to,_value));
        }
        else{
            assetSelector memory aselector = withdrawSelector[token];
            if (aselector.isValueFirst){
                (status,returnedData) = token.call(abi.encodeWithSignature( aselector.selector,_value,_to));
            }
            else {
                (status,returnedData)= token.call(abi.encodeWithSignature(aselector.selector,_to,_value));
            }
        }

        require(status && (returnedData.length == 0 || abi.decode(returnedData, (bool))),'withdraw failed');
        return true;
    }
}